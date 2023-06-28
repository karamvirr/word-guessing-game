require 'rails_helper'

RSpec.describe StagingAreaChannel, type: :channel do
  it "user can join a staging area" do
    room = create(:room)
    user = create(:user, name: nil, room: room)

    stub_connection(current_user: user)
    subscribe(slug: room.slug)

    expect(subscription).to(be_confirmed)
    expect(subscription).to(have_stream_for("staging_area_#{room.slug}"))
    expect(subscription).to(have_stream_for("staging_area_#{room.slug}_#{user.id}"))
  end
end
