require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "envía una Content-Security-Policy estricta" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("default-src 'self'")
    expect(csp).to include("frame-ancestors 'none'")
    expect(csp).not_to include("unsafe-inline")
  end

  it "deniega el framing con X-Frame-Options" do
    get root_path
    expect(response.headers["X-Frame-Options"]).to eq("DENY")
  end
end
