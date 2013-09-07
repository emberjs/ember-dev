class TestServer
  def call(environment)
    [200,
     {"Content-Type" => "text/plain", "Content-length" => "11" },
     ["Hello world"]]
  end
end

run TestServer.new
