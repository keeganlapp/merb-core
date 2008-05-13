require File.dirname(__FILE__) + '/../../spec_helper'

describe Merb::Router::Route, "initially" do
  predicate_matchers[:allow_fixation] = :allow_fixation?

  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @r1 = Merb::Router.routes.first
    @r5 = Merb::Router.routes[4]
  end

  it "has reader for conditions" do
    @r1.conditions
  end

  it "has reader for params" do
    @r1.params
  end

  it "has reader for behavior" do
    @r5.behavior
  end

  it "has reader for conditional block" do
    @r5.conditional_block
  end

  it "has reader for segments" do
    @r5.segments
  end

  it "has reader for index" do
    @r1.index.should == 0
  end

  it "has reader for symbol" do
    @r1.symbol
  end

  it "does not allow fixation" do
    @r1.should_not allow_fixation
  end
end


describe Merb::Router::Route, "#fixatable" do
  predicate_matchers[:allow_fixation] = :allow_fixation?

  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @route = Merb::Router.routes[4]
  end

  it "allows fixation when called with true" do
    @route.fixatable(true)

    @route.should allow_fixation
  end

  it "allows fixation when called with true" do
    @route.fixatable(true)
    @route.should allow_fixation

    @route.fixatable(false)
    @route.should_not allow_fixation
  end

  it "allows fixation when called with default argument" do
    @route.fixatable

    @route.should allow_fixation
  end
end



describe Merb::Router::Route, "#to_s" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @route = Merb::Router.routes[4]
  end

  it "concatenates route segments" do
    @route.stub!(:segments).and_return(["continents/", "new"])
    @route.to_s.should == "continents/new"
  end

  it "prefixes symbol segments with colon" do
    @route.stub!(:segments).and_return(["continents/", :id])
    @route.to_s.should == "continents/:id"
  end
end



describe Merb::Router::Route, "#register" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @route = Merb::Router.routes[4]
  end

  it "adds route to Merb routes set" do
    Merb::Router.routes = []
    @route.register

    Merb::Router.routes.should include(@route)
  end

  it "sets index on route" do
    Merb::Router.routes = []
    @route.register

    @route.index.should == 0
  end

  it "returns route itself" do
    Merb::Router.routes = []
    @route.register.should == @route
  end
end



describe Merb::Router::Route, "#symbol_segments" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @route = Merb::Router.routes[4]
  end

  after :each do
    Merb::Router.routes = []
  end

  it "cherrypicks segments that are Symbols" do
    @route.stub!(:segments).and_return(["prefix/", :controller, "ping"])
    @route.symbol_segments.should == [:controller]
  end
end



describe Merb::Router::Route, "#segments_from_path" do
  before :each do
    Merb::Router.prepare do |r|
      r.resources :continents do |c|
        c.resources :countries
      end
    end

    @route = Merb::Router.routes[4]
  end

  after :each do
    Merb::Router.routes = []
  end

  it "turns path into string and symbol segments" do
    @route.segments_from_path("prefix/:controller/:action/:id").should == ["prefix/", :controller, "/", :action, "/", :id]
  end

  it "handles slash edge case just fine" do
    @route.segments_from_path("/").should == ["/"]
  end
end



describe Merb::Router::Route, "#name" do
  before :each do
    Merb::Router.prepare do |r|
      r.match("/").to(:controller => "home")
    end

    @route = Merb::Router.routes.first
  end

  after :each do
    Merb::Router.routes = []
  end

  it "places the route into named routes collection" do
    @route.name(:home)

    Merb::Router.named_routes[:home].should == @route
  end

  it "only accepts Symbols" do
    lambda { @route.name("home") }.should raise_error(ArgumentError)
  end
end



describe Merb::Router::Route, "#regexp?" do
  before :each do
    Merb::Router.prepare do |r|
      r.match(/api\/(.*)/).to(:controller => "api", :token => "[1]").name(:regexpy)

      r.match("/what-is-regexps-dude").to(:controller => "plain_strings").name(:non_regexpy)
    end

    @regexp_route   = Merb::Router.named_routes[:regexpy]
    @non_regexp_route = Merb::Router.named_routes[:non_regexpy]
  end

  it "is true for routes that use regular expressions" do
    @regexp_route.should be_regexp
  end

  it "is false for routes that do not explicitly use regular expressions" do
    @non_regexp_route.should_not be_regexp
  end

  it "is true if behavior returns true when sent regexp?" do
    @non_regexp_route.stub!(:behavior).and_return(stub("regexp_behavior", :regexp? => true))
    @non_regexp_route.should be_regexp
  end

  it "is true if any of behavior's anscestors return true when sent regexp?" do
    @regexp_ancestor = stub("regexp_ancestor", :regexp? => true)
    @not_regexp_ancestor = stub("not_regexp_ancestor", :regexp? => false)
    @behavior_with_ancestors = stub("regexp_behavior", :regexp? => false, :ancestors => [@regexp_ancestor, @not_regexp_ancestor])

    @non_regexp_route.stub!(:behavior).and_return(@behavior_with_ancestors)
    @non_regexp_route.should be_regexp
  end

  after :each do
    Merb::Router.routes = []
  end
end



describe Merb::Router::Route, "#generate" do
  before :each do
    Merb::Router.prepend do |r|
      r.match(/api\/(.*)/).to(:controller => "api", :token => "[1]").name(:regexpy)
      r.match("/world/countries/:name").to(:controller => "countries").name(:non_regexpy)
    end

    @regexp_route   = Merb::Router.named_routes[:regexpy]
    @non_regexp_route = Merb::Router.named_routes[:non_regexpy]
  end

  it "does not work for regexp routes" do
    lambda { @regexp_route.generate({ :token => "apitoken" }) }.should raise_error(RuntimeError, /regexp/)
  end

  it "replaces symbol segments in the URL with values from given Hash parameters" do
     @non_regexp_route.generate({ :name => "Italy" }).should == "/world/countries/Italy"
    @non_regexp_route.generate({ :name => "Brazil" }).should == "/world/countries/Brazil"
  end

  it "replaces symbol segments with Fixnum  values just fine" do
    @non_regexp_route.generate({ :name => 101 }).should == "/world/countries/101"
  end

  it "appends unknown symbol segments after ?" do
    @non_regexp_route.generate({ :name => 101, :area => 10101 }).should == "/world/countries/101?area=10101"
  end

  it "calls #to_param on segments that respond to it" do
    @non_regexp_route.generate({ :name => stub('US', :to_param => 'USA') }).should == "/world/countries/USA"
  end
end
