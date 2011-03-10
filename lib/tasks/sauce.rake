namespace :screenshots do
  task :clean do
    FileUtils.rm_rf  Dir["screenshots/report/**/*-*-*"]
    FileUtils.rm  Dir["screenshots/report/**/*.html"]
  end

  desc "" #hide from rake -T screenshots
  Spec::Rake::SpecTask.new :runtests_spec do |t|
    t.spec_opts = ['--options', "\"#{Rails.root.join('spec', 'spec.opts')}\""]
    spec_glob = ENV["SAUCE_SPEC_GLOB"] || "screenshots/**/*_spec.rb"
    t.spec_files = FileList[spec_glob]
  end

  task :runtests_parallel do
    %x{ruby screenshots/parallel_sauce.rb}
  end

  task :runtests => :runtests_parallel

  task :report do
    %x{haml screenshots/report/index.html.haml > screenshots/report/index.html}
    %x{open screenshots/report/index.html}
  end

  task :push, :email, :needs => :environment do |t, args|
    args.with_defaults(:email => "loren@siebert.org")
    
    begin
      require 'cloudfiles'
    rescue LoadError => e
      $stderr.puts "Please run 'gem install cloudfiles'"
      raise e
    end
    cf = CloudFiles::Connection.new(:username => "lorensiebert", :api_key => "***REMOVED***")
    container = cf.container('SauceLabs Reports')

    Dir["screenshots/report/**/*.png"].each do |filename|
      image_obj = container.create_object filename.split('/')[-2..-1].join("/"), false
      image_obj.write(open(filename))
    end

    logo_obj = container.create_object "logo.gif", false
    logo_obj.write(open('screenshots/report/logo.gif'))

    js_obj = container.create_object "jquery-1.5.min.js", false
    js_obj.write(open('screenshots/report/jquery-1.5.min.js'))

    obj = container.create_object "saucelabs.html", false
    obj.write(open('screenshots/report/index.html'))

    puts obj.public_url
    Emailer.deliver_saucelabs_report(args.email, obj.public_url)
  end

  task :run do
    Rake::Task["screenshots:clean"].invoke
    Rake::Task["screenshots:runtests"].invoke
    Rake::Task["screenshots:report"].invoke
  end

  # Run the full report and email the link to someone: rake screenshots:run_and_report["email@example.com"]
  task :run_and_report, :email, :needs => :environment do |t, args|
    Rake::Task["screenshots:run"].invoke
    Rake::Task["screenshots:push"].invoke(args.email)
  end
end

desc "Run sauce tests, create screenshots"
task :screenshots => "screenshots:run"

