# Extend the Base ActionController to support multiple site
ActionController::Base.class_eval do 

  attr_accessor :current_site

  # Use this in your controller just like the <tt>layout</tt> macro.
  # Example:
  #
  #  site 'maybe_domain'
  #
  # -or-
  #
  #  site :get_site
  #
  #  def get_site
  #    'maybe_domain'
  #  end
  def self.site(site_name)
    write_inheritable_attribute "site", site_name
    before_filter :add_multisite_path
  end

  # Retrieves the current set site
  def current_site(passed_site=nil)
    site = passed_site || self.class.read_inheritable_attribute("site")

    @active_site = case site
      when Symbol then send(site)
      when Proc   then site.call(self)
      when String then site
    end
  end

  protected
  def add_multisite_path
    if current_site
      # It is not enough to set it on ActionController::Base because we are
      # are in a subclass at this point, so setting it here is too late.
      # 
      # However not setting it on ActionController::Base trips up other plugins
      # that assume that ActionController::Base.view_paths is always correct.
      [self, ActionController::Base].each do |o|
        # reset ActionControllers page cache dir to caches/xxxx/public
        o.page_cache_directory = File.join(RAILS_ROOT, 'caches', @active_site, 'public') 
        # reset ActionControllers view paths to app/views and prepend the current active site
        self.view_paths = [File.join(RAILS_ROOT, 'sites', @active_site, 'views'), File.join(RAILS_ROOT, 'app', 'views')]
      end
      logger.info "#{self.class}.page_cache_directory: " + self.page_cache_directory
      logger.info "#{self.class}.view_paths: " + self.view_paths.join(":")
    end
    return true
  end
end