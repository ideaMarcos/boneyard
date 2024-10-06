defmodule Boneyard.Presence do
  use Phoenix.Presence, otp_app: :boneyard, pubsub_server: Boneyard.PubSub
end
