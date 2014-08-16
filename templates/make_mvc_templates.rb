require "mysql2"
###below generates the model view controller files for all cost categories

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


 #generate the controllers and model and the wizard model files from templates
def gen_controller(model, flist , cntrl_fname, model_fname, wizard_fname)

   fsc = ''
   fszz  = ''
   flist.each do | f|
    fsc = fsc + ":" + f.to_s + ", "
    fszz = fsc +  ", :election_year_id, :county"
  end

   controller_result = IO.read(cntrl_fname) % {
   :model_up_pl  => model.capitalize,
   :model_up_sing   => model.capitalize.chomp('s'),
   :model_down_pl => model,
   :model_down_sing => model.chomp('s'),
   :fs =>  fszz,
   :ZZZ => '%w'  }

    model_result = IO.read(model_fname) % {
   :model_up_pl  => model.capitalize,
   :model_up_sing   => model.capitalize.chomp('s'),
   :model_down_pl => model,
   :model_down_sing => model.chomp('s'),
   :fs_items  => fsc }

   wizard_result = IO.read(wizard_fname) % {
   :model_up_sing   => model.capitalize.chomp('s')
  }
end

 #generates the view dir and files for each cost category
def gen_views(model,  flist,  view_file_list)
  view_file_list.each do | vf |
    viewitem = IO.read(vf)
    formstuff = <<-EOT
     #{viewitem}
    EOT
    #replace postage and postages
    newform =  formstuff.gsub(/postages/, model)   #model_down_pl
    newform  =  newform.gsub(/Postages/, model.capitalize)  #model_up_pl
    newform  =  newform.gsub(/postage/, model.capitalize.chomp('s'))  #model_up_sing
    newform  =  newform.gsub(/Postages/, model.capitalize)  #model_up_pl
    puts newform
  end
end


#############main###############


#get the model names
cntrl_fname = 'controller_template'
model_fname = 'model_template'
wizard_fname = 'wizard_template'
view_file_list =  ['_form_template' , 'edit_template']


#get the fields for each model
cxn  = connect_2_db
modlist = get_models
moddict =  get_fields_for_model(modlist)
moddict.each do | k, v |
    gen_controller(k, v, cntrl_fname, model_fname, wizard_fname)
    gen_views( k, v,  view_file_list)
end
