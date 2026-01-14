module Swaggify
  class Handler
    include HTTP::Handler

    @builder : Swagger::Builder

    macro finished
      def initialize(
        title : String = "Untitled API",
        version : String = {{ `shards version #{__DIR__}`.chomp.stringify }},
        description : String = "An example description, can be changed!",
        terms_url : String = "http://yourapp.com/terms",
        contact : Swagger::Contact = Swagger::Contact.new("John Doe", "john@doe.com", "https://john.doe"),
        license : Swagger::License = Swagger::License.new("MIT", "https://john.doe/mit"),
        authorizations : Array(Swagger::Authorization) = [] of Swagger::Authorization
      )
        @builder = Swagger::Builder.new(
          title: title,
          version: version,
          description: description,
          terms_url: terms_url,
          contact: contact,
          license: license,
          authorizations: authorizations
        )

        {% for klass in Grip::Controllers::HTTP.includers %}
          {% if klass.class? %}
            {% controller = klass.annotation(Swaggify::Controller) %}
            {% if controller %}
              {% actions = klass.methods.select { |m| m.annotation(Swaggify::Action) } %}

              @builder.add(Swagger::Controller.new(
                name: {{controller["name"]}},
                description: {{controller["description"]}},
                actions: [
                  {% for method in actions %}
                    {% action = method.annotation(Swaggify::Action) %}
                    Swagger::Action.new(
                      method: {{action["method"]}},
                      route: {{action["route"]}},
                      responses: {{action["responses"]}} || [] of Swagger::Response,
                      request: {{action["request"]}},
                      summary: {{action["summary"]}},
                      parameters: {{action["parameters"]}} || [] of Swagger::Parameter,
                      description: {{action["description"]}},
                      authorization: {{action["authorization"]}} || false,
                      deprecated: {{action["deprecated"]}} || false,
                    ),
                  {% end %}
                ] of Swagger::Action
              ))
            {% end %}
          {% end %}
        {% end %}
      end
    end

    def call(context : HTTP::Server::Context) : HTTP::Server::Context
      if context.request.path.includes?("document.json")
        context.response.headers.merge!({"Content-Type" => "application/json; charset=UTF-8"})
        context.response.print(@builder.built.to_json)
      else
        title = "Swagger UI"
        openapi_url = "/swagger/document.json"

        context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
        context.response.print(ECR.render("./lib/swagger/src/swagger/http/views/swagger.ecr"))
      end

      context
    end
  end
end
