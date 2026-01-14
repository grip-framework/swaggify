require "../src/swaggify"

@[Swaggify::Controller(name: "Test Controller", description: "A test controller to experiment with Swagger!")]
class TestController
  include Grip::Controllers::HTTP

  @[Swaggify::Action(
    method: "GET",
    route: "/v1/index/{id}",
    description: "Returns an example response for test purposes!",
    parameters: [
      Swagger::Parameter.new("id", "path"),
    ],
    responses: [
      Swagger::Response.new("200", "Success response"),
    ],
  )]
  def index(context)
    id = context.fetch_path_params.["id"]

    context
      .text("Hello, #{id}!")
      .halt
  end
end

class Application
  include Grip::Application

  property handlers : Array(HTTP::Handler) = [
    Grip::Handlers::Exception.new,
    Grip::Handlers::HTTP.new
  ] of HTTP::Handler

  def initialize
    routes
  end

  def routes
    scope "/v1" do
      get "/index/:id", TestController, as: :index
    end

    # Should be the last one, otherwise it is not visible!
    forward "/swagger/*", Swaggify::Handler,
      title: "Test API",
      version: {{ `shards version #{__DIR__}`.chomp.stringify }},
      description: "Documentation of my API",
      terms_url: "http://yourapp.com/terms",
      contact: Swagger::Contact.new("John Doe", "john@doe.com", "https://john.doe"),
      license: Swagger::License.new("MIT", "https://john.doe/mit"),
      authorizations: [] of Swagger::Authorization
  end
end

app = Application.new
app.run
