#
#  Copyright (c) 2014, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.
#

require "sinatra/base"
require "sinatra/get_or_post"

require "helpers/json_helper"
require "helpers/lookup_helper"
require "helpers/presentation_helper"

require "power/datacenter"
require "tire"
require "redis"

module Power
  class Application < Sinatra::Base
    extend Sinatra::GetOrPost

    set :root, File.expand_path("../..", __FILE__)

    configure do
      # disable frame protection
      set :protection, except: [:frame_options]

      # setup defaults
      set :center_lookup, Power::Datacenter
      set :cache_provider, Redis.new
      set :index_name, "measurements"

      Datacenter.from_file("config/datacenters.yml")
    end

    configure :staging, :production do
      require "rack/ssl"
      use Rack::SSL
    end

    helpers do
      include JsonHelper
      include LookupHelper
      include PresentationHelper
    end

    get "/timeline/:datacenter_slug/:period.json" do
      datacenter = datacenter_by_slug(params[:datacenter_slug])

      halt(404) unless datacenter

      json timeline_for(datacenter, params[:period]).cached_json
    end

    get_or_post "/:datacenter_slug" do
      datacenter = datacenter_by_slug(params[:datacenter_slug])

      halt(404) unless datacenter

      erb :index, :locals => { :datacenter => datacenter }
    end

    get_or_post "/" do
      redirect to("/#{first_datacenter.slug}")
    end
  end
end
