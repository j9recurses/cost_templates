require "mysql2"
 require 'fileutils'

###script below generates the model view controller files for all cost categories

def connect_2_db
  @db_host  = "localhost"
  @db_user  = "myrailsbuddy"
  @db_pass  = "mypass"
  @db_name = "caceo_costs_development"
  @client = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)
   return @client
  end

#get the model names from the db
def get_models
  result = @client.query("select distinct model_name from category_descriptions;")
  modlist = Array.new()
  result.each(:as => :array) do |row|
         modlist<< row
  end
  return modlist
end

#get the fields for each model
def get_fields_for_model(modlist)
  moddict = Hash.new{}
  modlist.each do | model |
    qry = "select distinct field from category_descriptions where model_name = '" + model[0].to_s + "';"
    fresult =  @client.query(qry)
    flist = Array.new()
    fresult.each(:as => :array) do |row|
       flist << row[0]
    end
    moddict[model[0]] = flist
  end
  return moddict
end

#make the model and controller dirs
def make_controllers_and_models_dir
    FileUtils::mkdir_p "controllers"
     FileUtils::mkdir_p "models"
end

 #generate the controllers and model and the wizard model files from templates
def gen_controller(model, flist , cntrl_fname, model_fname, wizard_fname)
   fsc = ''
   fszz  = ''
   flist.each do | f|
    fsc = fsc + ":" + f.to_s + ", "
    fszz = fsc +  " :election_year_id, :county, :current_step"
  end

   controller_result = IO.read(cntrl_fname) % {
   :model_up_pl  => model.capitalize,
   :model_up_sing   => model.capitalize.chomp('s'),
   :model_down_pl => model,
   :model_down_sing => model.chomp('s'),
   :fs =>  fszz,
   :ZZZ => '%w'  }
    ctrl_fname = "controllers/" + model + "_controller.rb"
    File.open(ctrl_fname, 'w') { |file| file.write( controller_result ) }
end

def gen_model (model, flist , cntrl_fname, model_fname, wizard_fname)
  #qrypers = "select fieldlist from filter_costs where filtertype = 'percent';"
  #fresultpers =  @client.query(qrypers)
  fpercentfilter = ''
  # fresultpers.each(:as => :array) do |row|
     # fpercentfilter = row[0]
#  end
  qrycom = "select fieldlist from filter_costs where filtertype = 'comment';"
  fresultcom =  @client.query(qrycom)
  fcomfilter = ''
  fresultcom.each(:as => :array) do |row|
     fcomfilter = row[0]
  end
  fsc = ''
  fsp = ''
   flist.each do | f|
    if fpercentfilter.include? f.to_s
      fsp =fsp + ":" + f.to_s + ", "
    elsif  fcomfilter.include? f.to_s
      bah = "bah"
    else
      fsc = fsc + ":" + f.to_s + ", "
    end
  end
  if  fsp.size == 0
    model_result = IO.read(model_fname) % {
   :model_up_pl  => model.capitalize,
   :model_up_sing   => model.capitalize.chomp('s'),
   :model_down_pl => model,
   :model_down_sing => model.chomp('s'),
   :fs_items  => fsc,
   :fs_percents => ''}
 end
 if fsp.size > 0
    fsp = "validates " +fsp +  "numericality:{only_integer: true, :greater_than_or_equal_to => 0, :less_than_or_equal_to  => 100,  :allow_nil => true, :allow_blank => false,  message: 'Entry is not valid. Please check your entry'  }"
    model_result = IO.read(model_fname) % {
   :model_up_pl  => model.capitalize,
   :model_up_sing   => model.capitalize.chomp('s'),
   :model_down_pl => model,
   :model_down_sing => model.chomp('s'),
   :fs_items  => fsc,
   :fs_percents => fsp }
end
    mod_fname = "models/" + model.chomp('s') + ".rb"
    File.open(mod_fname, 'w') { |file| file.write(  model_result ) }

   wizard_result = IO.read(wizard_fname) % {
   :model_up_sing   => model.capitalize.chomp('s')
   }
    wiz_fname = "models/wizard_" + model.chomp('s') + ".rb"
    File.open( wiz_fname, 'w') { |file| file.write(  wizard_result ) }
end


 #generates the view dir and files for each cost category
def gen_views(model,  flist,  view_file_dict, templatedir, viewsteps_fname )
    viewdir = 'views/' + model
  view_file_dict.each do | fn, vf |
    vf = templatedir + vf
    viewitem = IO.read(vf)
    formstuff = <<-EOT
     #{viewitem}
    EOT
    #replace postage and postages
    newform =  formstuff.gsub(/postages/, model)   #model_down_pl
    newform  =  newform.gsub(/Postages/, model.capitalize)  #model_up_pl
    newform  =  newform.gsub(/postage/, model.chomp('s') )  #model_up_sing
    newform  =  newform.gsub(/Postages/, model.capitalize)  #model_up_pl
    #make the view dir and write the files
    FileUtils::mkdir_p viewdir
    fname = viewdir + "/" + fn
    File.open(fname, 'w') { |file| file.write(newform) }
  end
   make_view_steps(model, viewsteps_fname,  flist, viewdir)
end

def make_view_steps(model, viewsteps_fname, flist, viewdir)
  #make the dir and write files
    stepsdir = viewdir + "/" + "steps"
    FileUtils::mkdir_p stepsdir
    #make the chunks for the _steps files
    chunks = flist.length.divmod(6)
    numb_of_chunks = chunks[0] + chunks[1]
    chunk_range = (1..numb_of_chunks).to_a
    chunk_range.each do | chunk|
      viewitem = IO.read(viewsteps_fname)
      stepstuff = <<-EOT
          #{viewitem}
       EOT
      chunk_step = (chunk -1).to_s
      mychunk = "[" + chunk_step +"]"
      newstepstuff  = stepstuff.gsub(/\[0\]/,  mychunk)
      fname = stepsdir +"/_page" + chunk.to_s + ".html.erb"
      File.open(fname, 'w') { |file| file.write(newstepstuff) }
    end
  end

#############main###############


#get the model names
templatedir = '/home/j9/Desktop/caceo_templates/cost_templates/templates/'
cntrl_fname = templatedir + 'controller_template'
model_fname =templatedir + 'model_template'
wizard_fname = templatedir + 'wizard_template'
view_file_dict =  { "_form.html.erb" => '_form_template' , "edit.html.erb" => 'edit_template', "_modal_info.html.erb" => '_model_info_template', "new.html.erb"  => 'new_template', "show.html.erb"  => 'show_template' }
viewsteps_fname  = templatedir + "steps_template"

#get the fields for each model
cxn  = connect_2_db
modlist = get_models
moddict =  get_fields_for_model(modlist)
make_controllers_and_models_dir
moddict.each do | k, v |
   gen_controller(k, v, cntrl_fname, model_fname, wizard_fname)
   gen_model(k, v , cntrl_fname, model_fname, wizard_fname)
   gen_views( k, v, view_file_dict, templatedir, viewsteps_fname )
end
