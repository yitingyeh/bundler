require 'spec_helper'

describe "bundle install" do

  describe "with bundler dependencies" do
    before(:each) do
      build_repo2 do
        build_gem "rails", "3.0" do |s|
          s.add_dependency "bundler", ">= 0.9.0.pre"
        end
        build_gem "bundler", "0.9.1"
        build_gem "bundler", Bundler::VERSION
      end
    end

    it "are forced to the current bundler version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      should_be_installed "bundler #{Bundler::VERSION}"
    end

    it "are not added if not already present" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      should_not_be_installed "bundler #{Bundler::VERSION}"
    end

    it "causes a conflict if explicitly requesting a different version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
        gem "bundler", "0.9.2"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, '')
        Fetching source index from file:#{gem_repo2}/
        Resolving dependencies...
        Bundler could not find compatible versions for gem "bundler":
          In Gemfile:
            bundler (= 0.9.2) ruby

          Current Bundler version:
            bundler (#{Bundler::VERSION})
        E
      expect(out).to include(nice_error)
    end

    it "works for gems with multiple versions in its dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"

        gem "multiple_versioned_deps"
      G


      install_gemfile <<-G
        source "file://#{gem_repo2}"

        gem "multiple_versioned_deps"
        gem "rack"
      G

      should_be_installed "multiple_versioned_deps 1.0.0"
    end

    it "includes bundler in the bundle when it's a child dependency" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      run "begin; gem 'bundler'; puts 'WIN'; rescue Gem::LoadError; puts 'FAIL'; end"
      expect(out).to eq("WIN")
    end

    it "allows gem 'bundler' when Bundler is not in the Gemfile or its dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      run "begin; gem 'bundler'; puts 'WIN'; rescue Gem::LoadError => e; puts e.backtrace; end"
      expect(out).to eq("WIN")
    end

    it "causes a conflict if child dependencies conflict" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activemerchant"
        gem "rails_fail"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, '')
        Fetching source index from file:#{gem_repo2}/
        Resolving dependencies...
        Bundler could not find compatible versions for gem "activesupport":
          In Gemfile:
            activemerchant (>= 0) ruby depends on
              activesupport (>= 2.0.0) ruby

            rails_fail (>= 0) ruby depends on
              activesupport (= 1.2.3) ruby
      E
      expect(out).to eq(nice_error)
    end

    it "causes a conflict if a child dependency conflicts with the Gemfile" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails_fail"
        gem "activesupport", "2.3.5"
      G

      nice_error = <<-E.strip.gsub(/^ {8}/, '')
        Fetching source index from file:#{gem_repo2}/
        Resolving dependencies...
        Bundler could not find compatible versions for gem "activesupport":
          In Gemfile:
            rails_fail (>= 0) ruby depends on
              activesupport (= 1.2.3) ruby

            activesupport (= 2.3.5) ruby
      E
      expect(out).to eq(nice_error)
    end

    it "can install dependencies with newer bundler version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G

      simulate_bundler_version "10.0.0"
      #simulate_new_machine

      bundle "check"
      expect(out).to include("The Gemfile's dependencies are satisfied")
    end
  end

end
