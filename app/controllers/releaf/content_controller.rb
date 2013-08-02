module Releaf
  class ContentController < BaseController
    helper_method :content_fields_to_display

    def content_fields_to_display obj_class
      if obj_class.respond_to? :releaf_fields_to_display
        obj_class.releaf_fields_to_display params[:action]
      else
        obj_class.column_names - %w[id created_at updated_at item_position]
      end
    end

    def fields_to_display
      return super unless params[:action] == 'show'
      return %w[name parent_id visible protected content]
    end

    def index
      @resources = Node.roots
    end


    def generate_url
      tmp_resource = nil

      if params[:id]
        tmp_resource = Node.find(params[:id])
      elsif params[:parent_id].blank? == false
        parent = Node.find(params[:parent_id])
        tmp_resource = parent.children.new
      else
        tmp_resource = Node.new
      end

      tmp_resource.name = params[:name]
      tmp_resource.slug = nil
      # FIXME calling private method
      tmp_resource.send(:ensure_unique_url)

      respond_to do |format|
        format.js { render :text => tmp_resource.slug }
      end
    end


    def save_and_respond request_type

      if request_type == :create
        content_type = _node_params[:content_type].constantize
        @resource = resource_class.new(_node_params)

        result = @resource.save

        form_extras
        @order_nodes = Node.where(:parent_id => (params[:parent_id] ? params[:parent_id] : nil))

        html_render_action = "new"

      elsif request_type == :update

        @resource = resource_class.find(params[:id])
        @resource.assign_attributes(_node_params)

        result = @resource.save

        form_extras
        @order_nodes = Node.where(:parent_id => (@resource.parent_id ? @resource.parent_id : nil)).where('id != :id', :id => params[:id])

        html_render_action = "edit"
      end

      respond_after_save request_type, result, html_render_action

   end


    def add_child
      @resource = resource_class.find(params[:id])

      Rails.application.eager_load!
      get_base_models

      respond_to do |format|
        format.html do
          render :layout => nil if params.has_key?(:ajax)
        end
      end

    end


    def new
      super
      @order_nodes = Node.where(:parent_id => (params[:parent_id] ? params[:parent_id] : nil))
      @item_position = 1
      @resource.parent_id = params[:parent_id]

      unless params[:parent_id].blank?
        parent = Node.find( params[:parent_id] )
        @ancestors = parent.ancestors
        @ancestors << parent
      end

      form_extras
    end

    def edit
      super
      @order_nodes = Node.where(:parent_id => (@resource.parent_id ? @resource.parent_id : nil)).where('id != :id', :id => params[:id])

      if @resource.higher_item
        @item_position = @resource.item_position
      else
        @item_position = 1
      end

      @ancestors = @resource.ancestors

      form_extras
    end

    def get_content_form
      Rails.application.eager_load!
      raise ArgumentError unless content_type_class_names.include? params[:content_type]
      @node = resource_class.find(params[:id])

      @resource = params[:content_type].constantize.new

      respond_to do |format|
        format.html { render :partial => 'get_content_form', :layout => false }
      end
    end

    def resource_class
      Node
    end

    protected

    def setup
      super
      @features[:show] = false
    end

    def _node_params
      params.require(:resource).permit!
    end

    private

    def content_type_class_names
      content_type_classes.map { |nc| nc.name }.sort
    end

    def content_type_classes
      NodeBase.node_classes + BlankNodeBase.node_classes
    end

    def form_extras
      Rails.application.eager_load!
      get_base_models

      new_content_if_needed
    end

    def resource_params
      []
    end

    def new_content_if_needed
      return if @resource.content
      if params[:content_type]
        if get_base_models.map { |bm| bm.name }.include? params[:content_type]
          @resource.content_type = params[:content_type]
          content_class = @resource.content_type.constantize
          if content_class.node_type == 'Releaf::NodeBase'
            @resource.content = @resource.content_type.constantize.new
          end
        end
      end
    end

    def get_base_models
      @base_models ||= content_type_classes
    end
  end
end
