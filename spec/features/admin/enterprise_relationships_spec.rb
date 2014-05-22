require 'spec_helper'

feature %q{
  As an Administrator
  I want to manage relationships between enterprises
}, js: true do
  include AuthenticationWorkflow
  include WebHelper


  context "as a site administrator" do
    before { login_to_admin_section }

    scenario "listing relationships" do
      # Given some enterprises with relationships
      e1, e2, e3, e4 = create(:enterprise), create(:enterprise), create(:enterprise), create(:enterprise)
      create(:enterprise_relationship, parent: e1, child: e2)
      create(:enterprise_relationship, parent: e3, child: e4)

      # When I go to the relationships page
      click_link 'Enterprises'
      click_link 'Relationships'

      # Then I should see the relationships
      within('table#enterprise-relationships') do
        page.should have_table_row [e1.name, 'permits', e2.name, '']
        page.should have_table_row [e3.name, 'permits', e4.name, '']
      end
    end


    scenario "creating a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')

      visit admin_enterprise_relationships_path
      select 'One', from: 'enterprise_relationship_parent_id'
      select 'Two', from: 'enterprise_relationship_child_id'
      click_button 'Create'

      page.should have_table_row [e1.name, 'permits', e2.name, '']
      EnterpriseRelationship.where(parent_id: e1, child_id: e2).should be_present
    end


    scenario "attempting to create a relationship with invalid data" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      create(:enterprise_relationship, parent: e1, child: e2)

      expect do
        # When I attempt to create a duplicate relationship
        visit admin_enterprise_relationships_path
        select 'One', from: 'enterprise_relationship_parent_id'
        select 'Two', from: 'enterprise_relationship_child_id'
        click_button 'Create'

        # Then I should see an error message
        page.should have_content "That relationship is already established."
      end.to change(EnterpriseRelationship, :count).by(0)
    end


    scenario "deleting a relationship" do
      e1 = create(:enterprise, name: 'One')
      e2 = create(:enterprise, name: 'Two')
      er = create(:enterprise_relationship, parent: e1, child: e2)

      visit admin_enterprise_relationships_path
      page.should have_table_row [e1.name, 'permits', e2.name, '']

      first("a.delete-enterprise-relationship").click

      page.should_not have_table_row [e1.name, 'permits', e2.name, '']
      EnterpriseRelationship.where(id: er.id).should be_empty
    end
  end

  context "as an enterprise user" do
    let!(:d1) { create(:distributor_enterprise) }
    let!(:d2) { create(:distributor_enterprise) }
    let(:enterprise_user) { create_enterprise_user([d1]) }

    before { login_to_admin_as enterprise_user }

    scenario "enterprise user can only add their own enterprises as parent" do
      visit admin_enterprise_relationships_path
      page.should have_select 'enterprise_relationship_parent_id', options: ['', d1.name]
      page.should have_select 'enterprise_relationship_child_id', options: ['', d1.name, d2.name]
    end
  end
end
