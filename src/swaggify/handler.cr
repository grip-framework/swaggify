module Swaggify
  class Handler
    include HTTP::Handler

    macro finished
      def initialize(
        title : String = "Untitled API",
        version : String = {{ `shards version #{__DIR__}`.chomp.stringify }},
        description : String = "An example description, can be changed!",
        terms_url : String = "http://yourapp.com/terms",
        contact : Swagger::Contact = Swagger::Contact.new("John Doe", "john@doe.com", "https://john.doe"),
        license : Swagger::License = Swagger::License.new("MIT", "https://john.doe/mit"),
        authorizations : Array(Swagger::Authorization) = [] of Swagger::Authorization)

        @builder = Swagger::Builder.new(
          title: title,
          version: version,
          description: description,
          terms_url: terms_url,
          contact: contact,
          license: license,
          authorizations: authorizations
        )

        {% for subclass in Grip::Controllers::Http.all_subclasses %}
          {% controller = subclass.resolve.annotation(Swaggify::Controller) %}
          {% actions = subclass.methods.map { |m| m.annotation(Swaggify::Action) } %}

          @builder.add(Swagger::Controller.new(
            name: {{controller["name"]}},
            description: {{controller["description"]}},
            actions: [{% for action in actions %} Swagger::Action.new(
              method: {{action["method"]}},
              route: {{action["route"]}},
              # Set default nil and empty values for non descriptive routes.
              responses: {{action["responses"]}} || [] of Swagger::Response,
              request: {{action["request"]}} || nil,
              summary: {{action["summary"]}} || nil,
              parameters: {{action["parameters"]}} || [] of Swagger::Parameter,
              description: {{action["description"]}} || nil,
              authorization: {{action["authorization"]}} || false,
              deprecated: {{action["deprecated"]}} || false), {% end %}] of Swagger::Action))
        {% end %}
      end
    end

    def call(context : HTTP::Server::Context) : HTTP::Server::Context
      if context.request.path.includes?("document.json")
        context.response.headers.merge!({"Content-Type" => "application/json; charset=UTF-8"})
        context.response.print(@builder.built.to_json)

        context
      else
        title = "Swagger UI"
        openapi_url = "/swagger/document.json"

        context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
        context.response.print(ECR.render("./lib/swagger/src/swagger/http/views/swagger.ecr"))

        context
      end
    end
  end
end
