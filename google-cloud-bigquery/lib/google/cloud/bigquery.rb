# Copyright 2015 Google Inc. All rights reserved.
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


require "google-cloud-bigquery"
require "google/cloud/bigquery/project"

module Google
  module Cloud
    ##
    # # Google Cloud BigQuery
    #
    # Google BigQuery enables super-fast, SQL-like queries against massive
    # datasets, using the processing power of Google's infrastructure. To learn
    # more, read [What is
    # BigQuery?](https://cloud.google.com/bigquery/what-is-bigquery).
    #
    # The goal of google-cloud is to provide an API that is comfortable to
    # Rubyists. Authentication is handled by {Google::Cloud#bigquery}. You can
    # provide the project and credential information to connect to the BigQuery
    # service, or if you are running on Google Compute Engine this configuration
    # is taken care of for you. You can read more about the options for
    # connecting in the [Authentication
    # Guide](https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/guides/authentication).
    #
    # To help you get started quickly, the first few examples below use a public
    # dataset provided by Google. As soon as you have [signed
    # up](https://cloud.google.com/bigquery/sign-up) to use BigQuery, and
    # provided that you stay in the free tier for queries, you should be able to
    # run these first examples without the need to set up billing or to load
    # data (although we'll show you how to do that too.)
    #
    # ## Listing Datasets and Tables
    #
    # A BigQuery project holds datasets, which in turn hold tables. Assuming
    # that you have not yet created datasets or tables in your own project,
    # let's connect to Google's `publicdata` project, and see what you find.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new project: "publicdata"
    #
    # bigquery.datasets.count #=> 1
    # bigquery.datasets.first.dataset_id #=> "samples"
    #
    # dataset = bigquery.datasets.first
    # tables = dataset.tables
    #
    # tables.count #=> 7
    # tables.map &:table_id #=> [..., "shakespeare", "trigrams", "wikipedia"]
    # ```
    #
    # In addition listing all datasets and tables in the project, you can also
    # retrieve individual datasets and tables by ID. Let's look at the structure
    # of the `shakespeare` table, which contains an entry for every word in
    # every play written by Shakespeare.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new project: "publicdata"
    #
    # dataset = bigquery.dataset "samples"
    # table = dataset.table "shakespeare"
    #
    # table.headers #=> ["word", "word_count", "corpus", "corpus_date"]
    # table.rows_count #=> 164656
    # ```
    #
    # Now that you know the column names for the Shakespeare table, you can
    # write and run a query.
    #
    # ## Running queries
    #
    # BigQuery supports two SQL dialects: [standard
    # SQL](https://cloud.google.com/bigquery/docs/reference/standard-sql/)
    # and the older [legacy
    # SQL](https://cloud.google.com/bigquery/docs/reference/legacy-sql),
    # as discussed in the guide [Migrating from legacy
    # SQL](https://cloud.google.com/bigquery/docs/reference/standard-sql/migrating-from-legacy-sql).
    #
    # In addition, BigQuery offers both synchronous and asynchronous methods, as
    # explained in [Querying
    # Data](https://cloud.google.com/bigquery/querying-data).
    #
    # ### Legacy SQL (formerly BigQuery SQL)
    #
    # Before version 2.0, BigQuery executed queries using a non-standard SQL
    # dialect known as BigQuery SQL. This variant is still the default, and will
    # be used unless you pass the flag `standard_sql: true` with your query.
    # (If you get an SQL syntax error with a query that may be written in
    # standard SQL, be sure that you are passing this option.)
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # sql = "SELECT TOP(word, 50) as word, COUNT(*) as count " \
    #       "FROM [publicdata:samples.shakespeare]"
    # data = bigquery.query sql
    # ```
    #
    # Notice that in legacy SQL, a fully-qualified table name uses the following
    # format: `[my-dashed-project:dataset1.tableName]`.
    #
    # ### Standard SQL
    #
    # Standard SQL is the preferred SQL dialect for querying data stored in
    # BigQuery. It is compliant with the SQL 2011 standard, and has extensions
    # that support querying nested and repeated data. It has several advantages
    # over legacy SQL, including:
    #
    # * Composability using `WITH` clauses and SQL functions
    # * Subqueries in the `SELECT` list and `WHERE` clause
    # * Correlated subqueries
    # * `ARRAY` and `STRUCT` data types
    # * Inserts, updates, and deletes
    # * `COUNT(DISTINCT <expr>)` is exact and scalable, providing the accuracy
    #   of `EXACT_COUNT_DISTINCT` without its limitations
    # * Automatic predicate push-down through `JOIN`s
    # * Complex `JOIN` predicates, including arbitrary expressions
    #
    # For examples that demonstrate some of these features, see [Standard SQL
    # highlights](https://cloud.google.com/bigquery/docs/reference/standard-sql/migrating-from-legacy-sql#standard_sql_highlights).
    #
    # Legacy SQL is still the default. To use standard SQL instead, pass the
    # option `standard_sql: true` with your query.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # sql = "SELECT word, SUM(word_count) AS word_count " \
    #       "FROM `bigquery-public-data.samples.shakespeare`" \
    #       "WHERE word IN ('me', 'I', 'you') GROUP BY word"
    # data = bigquery.query sql, standard_sql: true
    # ```
    #
    # Notice that in standard SQL, the format for a fully-qualified table name
    # uses back-ticks instead of brackets, and a dot instead of a semi-colon:
    # <code>`my-dashed-project.dataset1.tableName`</code>.
    #
    # #### Query parameters
    #
    # With standard SQL, you can use positional or named query parameters. This
    # example shows the use of named parameters:
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # sql = "SELECT word, SUM(word_count) AS word_count " \
    #       "FROM `bigquery-public-data.samples.shakespeare`" \
    #       "WHERE word IN UNNEST(@words) GROUP BY word"
    # data = bigquery.query sql, params: { words: ['me', 'I', 'you'] }
    # ```
    #
    # As demonstrated above, passing the `params` option will automatically set
    # `standard_sql` to `true`.
    #
    # #### Data types
    #
    # BigQuery standard SQL supports simple data types such as integers, as well
    # as more complex types such as `ARRAY` and `STRUCT`.
    #
    # The BigQuery data types are converted to and from Ruby types as follows:
    #
    # | BigQuery    | Ruby           | Notes  |
    # |-------------|----------------|---|
    # | `BOOL`      | `true`/`false` | |
    # | `INT64`     | `Integer`      | |
    # | `FLOAT64`   | `Float`        | |
    # | `STRING`    | `STRING`       | |
    # | `DATETIME`  | `DateTime`     | `DATETIME` does not support time zone. |
    # | `DATE`      | `Date`         | |
    # | `TIMESTAMP` | `Time`         | |
    # | `TIME`      | `Google::Cloud::BigQuery::Time` | |
    # | `BYTES`     | `File`, `IO`, `StringIO`, or similar | |
    # | `ARRAY`  | `Array` | Nested arrays and `nil` values are not supported. |
    # | `STRUCT`    | `Hash`         | Hash keys may be strings or symbols. |
    #
    # See [Data Types](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types)
    # for an overview of each BigQuery data type, including allowed values.
    #
    # ### Synchronous queries
    #
    # Let's start with the simpler synchronous approach. Notice that this time
    # you are connecting using your own default project. This is necessary for
    # running a query, since queries need to be able to create tables to hold
    # results.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # sql = "SELECT TOP(word, 50) as word, COUNT(*) as count " \
    #       "FROM publicdata:samples.shakespeare"
    # data = bigquery.query sql
    #
    # data.count #=> 50
    # data.next? #=> false
    # data.first #=> {"word"=>"you", "count"=>42}
    # ```
    #
    # The `TOP` function shown above is just one of a variety of functions
    # offered by BigQuery. See the [Query
    # Reference](https://cloud.google.com/bigquery/query-reference) for a full
    # listing.
    #
    # ### Asynchronous queries
    #
    # Because you probably should not block for most BigQuery operations,
    # including querying as well as importing, exporting, and copying data, the
    # BigQuery API enables you to manage longer-running jobs. In the
    # asynchronous approach to running a query, an instance of
    # {Google::Cloud::Bigquery::QueryJob} is returned, rather than an instance
    # of {Google::Cloud::Bigquery::QueryData}.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # sql = "SELECT TOP(word, 50) as word, COUNT(*) as count " \
    #       "FROM publicdata:samples.shakespeare"
    # job = bigquery.query_job sql
    #
    # job.wait_until_done!
    # if !job.failed?
    #   job.query_results.each do |row|
    #     puts row["word"]
    #   end
    # end
    # ```
    #
    # Once you have determined that the job is done and has not failed, you can
    # obtain an instance of {Google::Cloud::Bigquery::QueryData} by calling
    # {Google::Cloud::Bigquery::QueryJob#query_results}. The query results for
    # both of the above examples are stored in temporary tables with a lifetime
    # of about 24 hours. See the final example below for a demonstration of how
    # to store query results in a permanent table.
    #
    # ## Creating Datasets and Tables
    #
    # The first thing you need to do in a new BigQuery project is to create a
    # {Google::Cloud::Bigquery::Dataset}. Datasets hold tables and control
    # access to them.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    #
    # dataset = bigquery.create_dataset "my_dataset"
    # ```
    #
    # Now that you have a dataset, you can use it to create a table. Every table
    # is defined by a schema that may contain nested and repeated fields. The
    # example below shows a schema with a repeated record field named
    # `cities_lived`. (For more information about nested and repeated fields,
    # see [Preparing Data for
    # BigQuery](https://cloud.google.com/bigquery/preparing-data-for-bigquery).)
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    # dataset = bigquery.dataset "my_dataset"
    #
    # table = dataset.create_table "people" do |schema|
    #   schema.string "first_name", mode: :required
    #   schema.record "cities_lived", mode: :repeated do |nested_schema|
    #     nested_schema.string "place", mode: :required
    #     nested_schema.integer "number_of_years", mode: :required
    #   end
    # end
    # ```
    #
    # Because of the repeated field in this schema, we cannot use the CSV format
    # to load data into the table.
    #
    # ## Loading records
    #
    # In addition to CSV, data can be imported from files that are formatted as
    # [Newline-delimited JSON](http://jsonlines.org/) or
    # [Avro](http://avro.apache.org/), or from a Google Cloud Datastore backup.
    # It can also be "streamed" into BigQuery.
    #
    # To follow along with these examples, you will need to set up billing on
    # the [Google Developers Console](https://console.developers.google.com).
    #
    # ### Streaming records
    #
    # For situations in which you want new data to be available for querying as
    # soon as possible, inserting individual records directly from your Ruby
    # application is a great approach.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    # dataset = bigquery.dataset "my_dataset"
    # table = dataset.table "people"
    #
    # rows = [
    #     {
    #         "first_name" => "Anna",
    #         "cities_lived" => [
    #             {
    #                 "place" => "Stockholm",
    #                 "number_of_years" => 2
    #             }
    #         ]
    #     },
    #     {
    #         "first_name" => "Bob",
    #         "cities_lived" => [
    #             {
    #                 "place" => "Seattle",
    #                 "number_of_years" => 5
    #             },
    #             {
    #                 "place" => "Austin",
    #                 "number_of_years" => 6
    #             }
    #         ]
    #     }
    # ]
    # table.insert rows
    # ```
    #
    # There are some trade-offs involved with streaming, so be sure to read the
    # discussion of data consistency in [Streaming Data Into
    # BigQuery](https://cloud.google.com/bigquery/streaming-data-into-bigquery).
    #
    # ### Uploading a file
    #
    # To follow along with this example, please download the
    # [names.zip](http://www.ssa.gov/OACT/babynames/names.zip) archive from the
    # U.S. Social Security Administration. Inside the archive you will find over
    # 100 files containing baby name records since the year 1880. A PDF file
    # also contained in the archive specifies the schema used below.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    # dataset = bigquery.dataset "my_dataset"
    # table = dataset.create_table "baby_names" do |schema|
    #   schema.string "name", mode: :required
    #   schema.string "sex", mode: :required
    #   schema.integer "number", mode: :required
    # end
    #
    # file = File.open "names/yob2014.txt"
    # load_job = table.load file, format: "csv"
    # ```
    #
    # Because the names data, although formatted as CSV, is distributed in files
    # with a `.txt` extension, this example explicitly passes the `format`
    # option in order to demonstrate how to handle such situations. Because CSV
    # is the default format for load operations, the option is not actually
    # necessary. For JSON saved with a `.txt` extension, however, it would be.
    #
    # ## Exporting query results to Google Cloud Storage
    #
    # The example below shows how to pass the `table` option with a query in
    # order to store results in a permanent table. It also shows how to export
    # the result data to a Google Cloud Storage file. In order to follow along,
    # you will need to enable the Google Cloud Storage API in addition to
    # setting up billing.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new
    # dataset = bigquery.dataset "my_dataset"
    # source_table = dataset.table "baby_names"
    # result_table = dataset.create_table "baby_names_results"
    #
    # sql = "SELECT name, number as count " \
    #       "FROM baby_names " \
    #       "WHERE name CONTAINS 'Sam' " \
    #       "ORDER BY count DESC"
    # query_job = dataset.query_job sql, table: result_table
    #
    # query_job.wait_until_done!
    #
    # if !query_job.failed?
    #
    #   require "google/cloud/bigquery"
    #
    #   storage = Google::Cloud::Storage.new
    #   bucket_id = "bigquery-exports-#{SecureRandom.uuid}"
    #   bucket = storage.create_bucket bucket_id
    #   extract_url = "gs://#{bucket.id}/baby-names-sam.csv"
    #
    #   extract_job = result_table.extract extract_url
    #
    #   extract_job.wait_until_done!
    #
    #   # Download to local filesystem
    #   bucket.files.first.download "baby-names-sam.csv"
    #
    # end
    # ```
    #
    # If a table you wish to export contains a large amount of data, you can
    # pass a wildcard URI to export to multiple files (for sharding), or an
    # array of URIs (for partitioning), or both. See [Exporting Data From
    # BigQuery](https://cloud.google.com/bigquery/exporting-data-from-bigquery)
    # for details.
    #
    # ## Configuring retries and timeout
    #
    # You can configure how many times API requests may be automatically
    # retried. When an API request fails, the response will be inspected to see
    # if the request meets criteria indicating that it may succeed on retry,
    # such as `500` and `503` status codes or a specific internal error code
    # such as `rateLimitExceeded`. If it meets the criteria, the request will be
    # retried after a delay. If another error occurs, the delay will be
    # increased before a subsequent attempt, until the `retries` limit is
    # reached.
    #
    # You can also set the request `timeout` value in seconds.
    #
    # ```ruby
    # require "google/cloud/bigquery"
    #
    # bigquery = Google::Cloud::Bigquery.new retries: 10, timeout: 120
    # ```
    #
    # See the [BigQuery error
    # table](https://cloud.google.com/bigquery/troubleshooting-errors#errortable)
    # for a list of error conditions.
    #
    module Bigquery
      # Creates a new `Project` instance connected to the BigQuery service.
      # Each call creates a new connection.
      #
      # For more information on connecting to Google Cloud see the
      # [Authentication
      # Guide](https://googlecloudplatform.github.io/google-cloud-ruby/#/docs/guides/authentication).
      #
      # @param [String] project Identifier for a BigQuery project. If not
      #   present, the default project for the credentials is used.
      # @param [String, Hash] keyfile Keyfile downloaded from Google Cloud. If
      #   file path the file must be readable.
      # @param [String, Array<String>] scope The OAuth 2.0 scopes controlling
      #   the set of resources and operations that the connection can access.
      #   See # [Using OAuth 2.0 to Access Google #
      #   APIs](https://developers.google.com/identity/protocols/OAuth2).
      #
      #   The default scope is:
      #
      #   * `https://www.googleapis.com/auth/bigquery`
      # @param [Integer] retries Number of times to retry requests on server
      #   error. The default value is `3`. Optional.
      # @param [Integer] timeout Default timeout to use in requests. Optional.
      #
      # @return [Google::Cloud::Bigquery::Project]
      #
      # @example
      #   require "google/cloud/bigquery"
      #
      #   bigquery = Google::Cloud::Bigquery.new
      #   dataset = bigquery.dataset "my_dataset"
      #   table = dataset.table "my_table"
      #
      def self.new project: nil, keyfile: nil, scope: nil, retries: nil,
                   timeout: nil
        project ||= Google::Cloud::Bigquery::Project.default_project
        project = project.to_s # Always cast to a string
        fail ArgumentError, "project is missing" if project.empty?

        if keyfile.nil?
          credentials = Google::Cloud::Bigquery::Credentials.default(
            scope: scope)
        else
          credentials = Google::Cloud::Bigquery::Credentials.new(
            keyfile, scope: scope)
        end

        Google::Cloud::Bigquery::Project.new(
          Google::Cloud::Bigquery::Service.new(
            project, credentials, retries: retries, timeout: timeout))
      end
    end
  end
end
