# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"
require "google/cloud/translate"

describe Google::Cloud do
  describe "#translate" do
    it "calls out to Google::Cloud.translate" do
      gcloud = Google::Cloud.new
      stubbed_translate = ->(key, project: nil, keyfile: nil, scope: nil, retries: nil, timeout: nil) {
        project.must_be :nil?
        keyfile.must_be :nil?
        key.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        "translate-project-object-empty"
      }
      Google::Cloud.stub :translate, stubbed_translate do
        project = gcloud.translate
        project.must_equal "translate-project-object-empty"
      end
    end

    it "passes key to Google::Cloud.translate" do
      gcloud = Google::Cloud.new
      stubbed_translate = ->(key, project: nil, keyfile: nil, scope: nil, retries: nil, timeout: nil) {
        key.must_equal "this-is-the-api-key"
        project.must_be :nil?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        "translate-api-object-empty"
      }
      Google::Cloud.stub :translate, stubbed_translate do
        api = gcloud.translate "this-is-the-api-key"
        api.must_equal "translate-api-object-empty"
      end
    end

    it "passes key and options to Google::Cloud.translate" do
      gcloud = Google::Cloud.new
      stubbed_translate = ->(key, project: nil, keyfile: nil, scope: nil, retries: nil, timeout: nil) {
        key.must_equal "this-is-the-api-key"
        project.must_be :nil?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_equal 5
        timeout.must_equal 60
        "translate-api-object-empty"
      }
      Google::Cloud.stub :translate, stubbed_translate do
        api = gcloud.translate "this-is-the-api-key", retries: 5, timeout: 60
        api.must_equal "translate-api-object-empty"
      end
    end

    it "passes project and keyfile to Google::Cloud.translate" do
      gcloud = Google::Cloud.new "project-id", "keyfile-path"
      stubbed_translate = ->(key, project: nil, keyfile: nil, scope: nil, retries: nil, timeout: nil) {
        project.must_equal "project-id"
        keyfile.must_equal "keyfile-path"
        scope.must_be :nil?
        key.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        "translate-api-object"
      }
      Google::Cloud.stub :translate, stubbed_translate do
        api = gcloud.translate
        api.must_equal "translate-api-object"
      end
    end

    it "passes project and keyfile and options to Google::Cloud.translate" do
      gcloud = Google::Cloud.new "project-id", "keyfile-path"
      stubbed_translate = ->(key, project: nil, keyfile: nil, scope: nil, retries: nil, timeout: nil) {
        project.must_equal "project-id"
        keyfile.must_equal "keyfile-path"
        scope.must_be :nil?
        key.must_be :nil?
        retries.must_equal 5
        timeout.must_equal 60
        "translate-api-object-scoped"
      }
      Google::Cloud.stub :translate, stubbed_translate do
        api = gcloud.translate retries: 5, timeout: 60
        api.must_equal "translate-api-object-scoped"
      end
    end
  end

  describe ".translate" do
    let(:default_credentials) { OpenStruct.new empty: true }
    let(:found_credentials) { "{}" }

    it "gets defaults for api key" do
      stubbed_env = ->(name) {
        "found-api-key" if name == "GOOGLE_CLOUD_KEY"
      }
      stubbed_service = ->(project, keyfile, scope: nil, retries: nil, timeout: nil, key: nil) {
        key.must_equal "found-api-key"
        project.must_be :empty?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new key: key
      }

      # Clear all environment variables
      # ENV.stub :[], nil do
      ENV.stub :[], stubbed_env do
        Google::Cloud::Translate::Service.stub :new, stubbed_service do
          translate = Google::Cloud.translate
          translate.must_be_kind_of Google::Cloud::Translate::Api
          translate.service.must_be_kind_of OpenStruct
          translate.service.key.must_equal "found-api-key"
        end
      end
    end

    it "uses provided api key" do
      stubbed_service = ->(project, keyfile, scope: nil, retries: nil, timeout: nil, key: nil) {
        key.must_equal "my-api-key"
        project.must_be :empty?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new key: key
      }

      # Clear all environment variables
      ENV.stub :[], nil do
        Google::Cloud::Translate::Service.stub :new, stubbed_service do
          translate = Google::Cloud.translate "my-api-key"
          translate.must_be_kind_of Google::Cloud::Translate::Api
          translate.service.must_be_kind_of OpenStruct
          translate.service.key.must_equal "my-api-key"
        end
      end
    end

    it "gets defaults for project_id and keyfile" do
      # Clear all environment variables
      ENV.stub :[], nil do
        # Get project_id from Google Compute Engine
        Google::Cloud::Core::Environment.stub :project_id, "project-id" do
          Google::Cloud::Translate::Credentials.stub :default, default_credentials do
            translate = Google::Cloud.translate
            translate.must_be_kind_of Google::Cloud::Translate::Api
            translate.project.must_equal "project-id"
            translate.service.credentials.must_equal default_credentials
          end
        end
      end
    end

    it "uses provided project_id and keyfile" do
      stubbed_credentials = ->(keyfile, scope: nil) {
        keyfile.must_equal "path/to/keyfile.json"
        scope.must_be :nil?
        "translate-credentials"
      }
      stubbed_service = ->(project, keyfile, scope: nil, retries: nil, timeout: nil, key: nil) {
        project.must_equal "project-id"
        keyfile.must_equal "translate-credentials"
        scope.must_be :nil?
        key.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new project: project
      }

      # Clear all environment variables
      ENV.stub :[], nil do
        File.stub :file?, true, ["path/to/keyfile.json"] do
          File.stub :read, found_credentials, ["path/to/keyfile.json"] do
            Google::Cloud::Translate::Credentials.stub :new, stubbed_credentials do
              Google::Cloud::Translate::Service.stub :new, stubbed_service do
                translate = Google::Cloud.translate project: "project-id", keyfile: "path/to/keyfile.json"
                translate.must_be_kind_of Google::Cloud::Translate::Api
                translate.project.must_equal "project-id"
                translate.service.must_be_kind_of OpenStruct
              end
            end
          end
        end
      end
    end
  end

  describe "Translate.new" do
    let(:default_credentials) { OpenStruct.new empty: true }
    let(:found_credentials) { "{}" }

    it "gets defaults for api key" do
      stubbed_env = ->(name) {
        "found-api-key" if name == "GOOGLE_CLOUD_KEY"
      }
      stubbed_service = ->(project, keyfile, scope: nil, retries: nil, timeout: nil, key: nil) {
        key.must_equal "found-api-key"
        project.must_be :empty?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new key: key
      }

      # Clear all environment variables
      # ENV.stub :[], nil do
      ENV.stub :[], stubbed_env do
        Google::Cloud::Translate::Service.stub :new, stubbed_service do
          translate = Google::Cloud::Translate.new
          translate.must_be_kind_of Google::Cloud::Translate::Api
          translate.service.must_be_kind_of OpenStruct
          translate.service.key.must_equal "found-api-key"
        end
      end
    end

    it "uses provided api key" do
      stubbed_service = ->(project, keyfile, scope: nil, retries: nil, timeout: nil, key: nil) {
        key.must_equal "my-api-key"
        project.must_be :empty?
        keyfile.must_be :nil?
        scope.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new key: key
      }

      # Clear all environment variables
      ENV.stub :[], nil do
        Google::Cloud::Translate::Service.stub :new, stubbed_service do
          translate = Google::Cloud::Translate.new key: "my-api-key"
          translate.must_be_kind_of Google::Cloud::Translate::Api
          translate.service.must_be_kind_of OpenStruct
          translate.service.key.must_equal "my-api-key"
        end
      end
    end

    it "gets defaults for project_id and keyfile" do
      # Clear all environment variables
      ENV.stub :[], nil do
        # Get project_id from Google Compute Engine
        Google::Cloud::Core::Environment.stub :project_id, "project-id" do
          Google::Cloud::Translate::Credentials.stub :default, default_credentials do
            translate = Google::Cloud::Translate.new
            translate.must_be_kind_of Google::Cloud::Translate::Api
            translate.project.must_equal "project-id"
            translate.service.credentials.must_equal default_credentials
          end
        end
      end
    end

    it "uses provided project_id and keyfile" do
      stubbed_credentials = ->(keyfile, scope: nil) {
        keyfile.must_equal "path/to/keyfile.json"
        scope.must_be :nil?
        "translate-credentials"
      }
      stubbed_service = ->(project, credentials, scope: nil, key: nil, retries: nil, timeout: nil) {
        project.must_equal "project-id"
        credentials.must_equal "translate-credentials"
        scope.must_be :nil?
        key.must_be :nil?
        retries.must_be :nil?
        timeout.must_be :nil?
        OpenStruct.new project: project
      }

      # Clear all environment variables
      ENV.stub :[], nil do
        File.stub :file?, true, ["path/to/keyfile.json"] do
          File.stub :read, found_credentials, ["path/to/keyfile.json"] do
            Google::Cloud::Translate::Credentials.stub :new, stubbed_credentials do
              Google::Cloud::Translate::Service.stub :new, stubbed_service do
                translate = Google::Cloud::Translate.new project: "project-id", keyfile: "path/to/keyfile.json"
                translate.must_be_kind_of Google::Cloud::Translate::Api
                translate.project.must_equal "project-id"
                translate.service.must_be_kind_of OpenStruct
              end
            end
          end
        end
      end
    end
  end
end
