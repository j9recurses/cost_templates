class SsothsController < ApplicationController
before_action :authenticate_user
before_action :get_user, :get_year,  :get_model_name, :get_category_path
before_action :get_category_description, :make_chunks,  except: [:destroy]
before_action :load_product, :set_ssoth, only: [:show, :update, :edit, :destroy]
before_action :load_wizard, only: [:new, :edit, :create, :update]
before_action :get_filtered, only:[:show]

  def index
   chk = @category.pluck(:started).to_s
   if chk == "[true]"
        id = Ssoth.where(county: @user[:county], election_year_id: @election_year_id).pluck(:id).last
         redirect_to ssoth_path(id)
   else
      redirect_to new_ssoth_path
    end
  end

  def show
    @ssoth = Ssoth.find(params[:id])
  end

  def new
     @ssoth =@wizard.object
  end

  def edit
  end

  def create
      @ssoth= @wizard.object
      @year_element = @election_year.year_elements.create(:element => @ssoth)
      if @wizard.save && @year_element.save
        Ssoth.category_status(@category_id, @ssoth)
        redirect_to @ssoth, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Saved."
      else
        render :new
       end
    end


  def update
     if @wizard.save
      Ssoth.category_status( @category_id, @ssoth)
      redirect_to @ssoth, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Updated."
    else
      render action: 'edit'
    end
  end

  def destroy
    Ssoth.remove_category_status(@category_id)
    @ssoth.destroy
    redirect_to ssoths_path
  end


  private
    def set_ssoth
      @ssoth = Ssoth.find(params[:id])
    end

    def get_model_name
      @model_name = "ssoths"
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
    @ssoth = Ssoth.find(params[:id])
  end

  def load_wizard
    @wizard = ModelWizard.new(@ssoth || Ssoth, session, params)
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
     @modal_stuff  = Ssoth.make_modals(@category_description)
  end

  def make_chunks
    @form_chunks = Ssoth.make_chunks(@model_name)
  end


#change params to get working
    # Never trust parameters from the scary internet, only allow the white list through.
    def ssoth_params
      params.require(:ssoth).permit(
      :ssothoutrea, :ssothoutream, :ssothrevm, :ssothhotm, :ssothdatam, :ssothwareh, :ssothelcom, :ssothphbank, :ssothwebsite, :ssothcpst, :ssothoth, :ssothothm, :ssothcomment,  :election_year_id, :county, :current_step
      )
    end
end
