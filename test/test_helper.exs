opts = StripeManaged.TestHelpers.start_mock_server()
Application.put_env(:stripe_managed, :test_opts, opts)

ExUnit.start(exclude: [:integration])
