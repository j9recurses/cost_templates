class SalmedsController < ApplicationController
before_action :authenticate_user
before_action :get_user, :get_year,  :get_model_name, :get_category_path
before_action :get_category_description, :make_chunks,  except: [:destroy]
before_action :load_product, :set_salmed, only: [:show, :update, :edit, :destroy]
before_action :load_wizard, only: [:new, :edit, :create, :update]
before_action :get_filtered, only:[:show]

  def index
   chk = @category.pluck(:started).to_s
   if chk == "[true]"
        id = Salmed.where(county: @user[:county], election_year_id: @election_year_id).pluck(:id).last
         redirect_to salmed_path(id)
   else
      redirect_to new_salmed_path
    end
  end

  def show
    @salmed = Salmed.find(params[:id])
  end

  def new
     @salmed =@wizard.object
  end

  def edit
  end

  def create
      @salmed= @wizard.object
      @year_element = @election_year.year_elements.create(:element => @salmed)
      if @wizard.save && @year_element.save
        Salmed.category_status(@category_id, @salmed)
        redirect_to @salmed, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Saved."
      else
        render :new
       end
    end


  def update
     if @wizard.save
      Salmed.category_status( @category_id, @salmed)
      redirect_to @salmed, notice: "The " + @category_name  +  " Costs That You Entered For " + @election_year[:year] .to_s + " were Successfully Updated."
    else
      render action: 'edit'
    end
  end

  def destroy
    Salmed.remove_category_status(@category_id)
    @salmed.destroy
    redirect_to salmeds_path
  end


  private
    def set_salmed
      @salmed = Salmed.find(params[:id])
    end

    def get_model_name
      @model_name = "salmeds"
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
    @salmed = Salmed.find(params[:id])
  end

  def load_wizard
    @wizard = ModelWizard.new(@salmed || Salmed, session, params)
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
     @modal_stuff  = Salmed.make_modals(@category_description)
  end

  def make_chunks
    @form_chunks = Salmed.make_chunks(@model_name)
  end


#change params to get working
    # Never trust parameters from the scary internet, only allow the white list through.
    def salmed_params
      params.require(:salmed).permit(
      :salmedprep, :salmedhandl, :salmedcampm, :salmedpsrp, :salmedpsop, :salmedtsrp, :salmedtsop, :salmedbeps, :salmedbepsp, :salmedbets, :salmedbetsp, :salmedhrsps, :salmedhrsts, :salmedcomment,  :election_year_id, :county, :current_step
      )
    end
end
