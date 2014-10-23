class SsvehsController < ApplicationController
before_action :authenticate_user
before_action :get_user, :get_year,  :get_model_name, :get_category_path
before_action :get_category_description, :make_chunks,  except: [:destroy]
before_action :load_product, :set_ssveh, only: [:show, :update, :edit, :destroy]
before_action :load_wizard, only: [:new, :edit, :create, :update]
before_action :get_filtered, only:[:show]

  def index
   chk = @category.pluck(:started).to_s
   if chk == "[true]"
        id = Ssveh.where(county: @user[:county], election_year_id: @election_year_id).pluck(:id).last
         redirect_to ssveh_path(id)
   else
      redirect_to new_ssveh_path
    end
  end

  def show
    @ssveh = Ssveh.find(params[:id])
  end

  def new
     @ssveh =@wizard.object
  end

  def edit
  end

  def create
      @ssveh= @wizard.object
      @year_element = @election_year.year_elements.create(:element => @ssveh)
      if @wizard.save && @year_element.save
        Ssveh.category_status(@category_id, @ssveh)
        redirect_to @ssveh, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Saved."
      else
        render :new
       end
    end


  def update
     if @wizard.save
      Ssveh.category_status( @category_id, @ssveh)
      redirect_to @ssveh, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Updated."
    else
      render action: 'edit'
    end
  end

  def destroy
    Ssveh.remove_category_status(@category_id)
    @ssveh.destroy
    redirect_to ssvehs_path
  end


  private
    def set_ssveh
      @ssveh = Ssveh.find(params[:id])
    end

    def get_model_name
      @model_name = "ssvehs"
    end

     def get_filtered
      c = FilterCost.where(filtertype: "comment").pluck(:fieldlist)
      @filtercomments =  eval(c[0])
      p = FilterCost.where(filtertype: "percent").pluck(:fieldlist)
      @filterpercents = eval(p[0])
       h = FilterCost.where(filtertype: "hour").pluck(:fieldlist)
      @filterhours = eval(h[0])
    end


  def load_product
    @ssveh = Ssveh.find(params[:id])
  end

  def load_wizard
    @wizard = ModelWizard.new(@ssveh || Ssveh, session, params)
    if self.action_name.in? %w[new edit]
      @wizard.start
    elsif self.action_name.in? %w[create update]
      @wizard.process
    end
  end

  def get_category_path
    @category= Category.where(election_year_id: @election_year_id, county: @user[:county],  model_name: @model_name)
    @category_id =  @category.pluck(:id).first
    @election_year_name = @election_year[:year].to_s
    @categories_path =  "link_to 'Back to Cost Categories for " +@election_year_name   +" ', election_year_categories_path(" + session[:election_year].to_s  + ")"
  end

  def get_category_description
    @category_description = CategoryDescription.where(model_name: @model_name)
     @category_name = CategoryDescription.where(model_name: @model_name).pluck(:name).first.titleize
     @modal_stuff  = Ssveh.make_modals(@category_description)
  end

  def make_chunks
    @form_chunks = Ssveh.make_chunks(@model_name)
  end


#change params to get working
    # Never trust parameters from the scary internet, only allow the white list through.
    def ssveh_params
      params.require(:ssveh).permit(
      :ssvehrent, :ssvehcount, :ssvehfuel, :ssvehins, :ssvehcomment,  :election_year_id, :county, :current_step
      )
    end
end
