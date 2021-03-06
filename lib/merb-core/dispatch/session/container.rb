module Merb
  class SessionContainer < Mash
  
    class_inheritable_accessor :session_store_type
    cattr_accessor :subclasses 
    self.subclasses = []
  
    attr_reader :session_id
    attr_accessor :needs_new_cookie
  
    class << self
  
      # Register the subclass as an available session store type.
      def inherited(klass)
        self.subclasses << klass.to_s
        super
      end

      # Generates a new session ID and creates a new session.
      #
      # ==== Returns
      # SessionContainer:: The new session.
      def generate
      end
    
      # ==== Parameters
      # request<Merb::Request>:: The Merb::Request that came in from Rack.
      #
      # ==== Returns
      # SessionContainer:: a SessionContainer. If no sessions were found, 
      # a new SessionContainer will be generated.
      def setup(request)
      end    
    
    end
  
    # ==== Parameters
    # session_id<String>:: A unique identifier for this session.
    def initialize(session_id)
      @_destroy = false
      self.session_id = session_id
    end
    
    # Assign a new session_id.
    #
    # Recreates the cookie with the default expiration time. Useful during log
    # in for pushing back the expiration date.
    def session_id=(sid)
      self.needs_new_cookie = (@session_id && @session_id != sid)
      @session_id = sid
    end
  
    # Teardown and/or persist the current session.
    #
    # If @_destroy is true, clear out the session completely, including
    # removal of the session cookie itself.
    #
    # ==== Parameters
    # request<Merb::Request>:: The Merb::Request that came in from Rack.
    def finalize(request)
    end
  
    # Destroy the current session - clears data and removes session cookie.
    def clear!
      @_destroy = true
      self.clear
    end
  
    # Regenerate the session_id.
    def regenerate
    end

  end
end