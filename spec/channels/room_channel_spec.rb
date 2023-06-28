require 'rails_helper'

RSpec.describe RoomChannel, type: :channel do
  it "user can join a room" do
    room = create(:room)
    user = create(:user, room: room)

    stub_connection(current_user: user)
    subscribe(slug: room.slug)

    expect(subscription).to(be_confirmed)
    expect(subscription).to(have_stream_for("room_#{room.slug}"))
    expect(subscription).to(have_stream_for("room_#{room.slug}_#{user.id}"))
  end
end
