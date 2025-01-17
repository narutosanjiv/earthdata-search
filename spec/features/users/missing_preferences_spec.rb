require 'spec_helper'

describe "User missing ordering preferences", reset: false do
  collection_id = 'C90762182-LAADS'
  collection_title = 'MODIS/Aqua Calibrated Radiances 5-Min L1B Swath 250m V005'

  context "when configuring a data access request" do
    before :all do
      load_page :search, project: [collection_id], view: :project
      wait_for_xhr

      login 'edscbasic'

      click_link "Retrieve project data"

      choose "FtpPushPull"
      select 'FtpPull', from: 'Distribution Options'
      click_button "Continue"
    end

    it "does not show an error message", intermittent: 1 do
      expect(page).to have_no_content('Contact information could not be loaded, please try again later')
    end
  end

  context "when accessing downloadable data" do
    before :all do
      load_page :search, project: [collection_id], view: :project
      wait_for_xhr

      login 'edscbasic'

      click_link "Retrieve project data"

      choose 'Download'
      click_button 'Submit'
    end

    it "shows the data retrieval page" do
      expect(page).to have_link("MODIS Level 1B Product Information Page at MCST (MiscInformation)")
    end
  end
end
