# coding:utf-8
module PlainSite
  module Commands
    require 'pp'
    require 'fileutils'
    require 'commander/import'
    require 'PlainSite/Site'

    SELF_DIR=File.dirname(__FILE__)

    def self.die(msg="\nExit now.\n")
      $stderr.puts msg
      exit 1
    end

    def self.run(action,args,opts)
      root=opts.root || Dir.pwd

      trap('INT') {self.die}
      trap('TERM') {self.die}

      unless File.exist? root
        say_error "Site root directory does not exist:#{root}"
        say_error "Create now? [Y/n]"
        answer=$stdin.gets.strip.downcase # `agree` cannot set default answer
        answer='y' if answer.empty?
        if answer =='y'
          FileUtils.mkdir_p root
        else
          self.die
        end
      end
      root=File.realpath root
      site=Site.new root
      self.send action,site,args,opts
    end

    def self.init(site,args,opts)
      site.init_scaffold opts.override
      puts 'Site scaffold init success!'
    end

    def self.build(site,includes,opts)
      site.build(dest:opts.dest,all:opts.all,local:opts.local,includes:includes)
      puts 'Posts build finished.'
      self.clean(site)
    end

    def self.clean(site,args=nil,opts=nil)
      if site.isolated_files.empty?
        puts "No isolated files found."
      else
        puts 'Do you really want to remove these isolated files?'
        puts ((site.isolated_files.map {|f| f[(site.dest.length+1)..-1]}).join "\n")
        puts "[y/N]"
        answer=$stdin.gets.strip.downcase
        answer='n' if answer.empty?
        if answer =='y'
          site.clean
          puts 'Clean finished.'
        end
      end
    end

    def self.serve(site,args,opts)
      site.serve(host:opts.host,port:opts.port)
    end

    def self.newpost(site,args,opts)
      path=site.newpost args[0],args[1]
      puts "New post created at:#{path}"
    end

  end
end

