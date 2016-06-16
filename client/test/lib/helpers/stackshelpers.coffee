helpers              = require '../helpers/helpers.js'
teamsHelpers         = require '../helpers/teamshelpers.js'
stackEditorUrl       = "#{helpers.getUrl(yes)}/Home/stacks"
stackSelector        = null
sectionSelector      = '.kdview.kdtabpaneview.stacks'
newStackButton       = '.kdbutton.GenericButton.HomeAppView-Stacks--createButton'
teamStacksSelector   = '.HomeAppView--section.team-stacks'
stackTemplate        = "#{teamStacksSelector} .HomeAppViewListItem.StackTemplateItem"
draftStacksSelector  = '.HomeAppView--section.drafts'
menuSelector         = '.SidebarMenu.kdcontextmenu .kdlistitemview-contextitem.default'
editSelector         = "#{menuSelector}:nth-of-type(1)"
stackEditorView      = '.StackEditorView'
deletebutton         = '.HomeAppView--button.danger'
sideBarSelector      = '#main-sidebar'
teamHeaderSelector   = '.SidebarTeamSection .SidebarStackSection.active h4'
draftStackHeader     = '.SidebarTeamSection .SidebarSection.draft'
removeStackModal     = '[testpath=RemoveStackModal]'
removeButton         = '.kdbutton.solid.red.medium'
visibleStack         = '[testpath=StackEditor-isVisible]'
stackEditorHeader    = "#{visibleStack} .StackEditorView--header"
stackTemplateNameArea  = "#{stackEditorHeader} .kdinput.text.template-title.autogrow"
saveButtonSelector     = "#{visibleStack} .StackEditorView--header .kdbutton.GenericButton.save-test"
stackEditorTab         = "#{visibleStack} .kdview.kdtabview.StackEditorTabs"
credentialsTabSelector = "div.kdtabhandle.credentials"
listCredential         = '.kdview.stacks.stacks-v2'

module.exports =

  clickNewStackButton: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible sectionSelector, 20000
      .click newStackButton
      .pause 2000
      .assert.urlContains '/Stack-Editor/New'
      .pause 1000, done

  seeTeamStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .url stackEditorUrl
      .waitForElementVisible teamStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000, done

  seePrivateStackTemplates: (browser, done) ->
    # FIXME: reimplement after stacks page is done ~ HK
    # privateStacksSelector = '.HomeAppView--section.private-stacks'
    # stackTemplate = "#{privateStacksSelector} .HomeAppViewListItem.StackTemplateItem"

    # browser
    #   .pause 2000
    #   .waitForElementVisible privateStacksSelector, 20000
    #   .waitForElementVisible stackTemplate, 20000

  seeDraftStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible draftStacksSelector, 20000
      .waitForElementVisible stackTemplate, 20000, done


  deleteStackTemplatesInUse: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible teamHeaderSelector, 20000
      .click teamHeaderSelector
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .waitForElementVisible deletebutton, 20000
      .click deletebutton
      .waitForElementVisible '.kdnotification', 20000
      .assert.containsText '.kdnotification', 'This template currently in use by the Team.', done


  deleteStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible draftStackHeader, 20000
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .waitForElementVisible deletebutton, 20000
      .click deletebutton
      .waitForElementVisible removeStackModal, 20000
      .click removeButton
      .pause 1000, done

  editStackTemplates: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible draftStackHeader, 20000
      .click draftStackHeader
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .waitForElementVisible stackTemplateNameArea, 2000
      .clearValue stackTemplateNameArea
      .pause 1000
      .setValue stackTemplateNameArea, 'NewStackName'
      .click saveButtonSelector, =>
        teamsHelpers.waitUntilToCreatePrivateStack browser, ->
          browser
            .refresh()
            .waitForElementVisible stackEditorView, 20000
            .waitForElementVisible stackTemplateNameArea, 2000
            .getAttribute stackTemplateNameArea, 'placeholder', (result) -> 
              this.assert.equal result.value, 'NewStackName'
          browser.pause 1000, done
            
  deleteCredentialInUsebrowser: (browser, done) ->
    browser
      .pause 2000
      .waitForElementVisible sideBarSelector, 20000
      .click sideBarSelector
      .waitForElementVisible teamHeaderSelector, 20000
      .click teamHeaderSelector
      .waitForElementVisible menuSelector, 20000
      .pause 2000
      .click editSelector
      .waitForElementVisible stackEditorView, 20000
      .click credentialsTabSelector
      .waitForElementVisible listCredential, 20000

    browser.elements "css selector", ".StackEditor-CredentialItem--info .custom-tag.inuse", (result) ->
      index = 0
      result.value.map (value) ->
        index += 1
        browser.elementIdText value.ELEMENT, (res) ->
          if res.value is 'IN USE'
            browser.assert.equal res.value, 'IN USE'
            browser.elementIdClick value.ELEMENT
            browser.pause 2000, ->
              browser.elements "css selector", ".kdbutton.solid.compact.outline.red.secondary.delete", (buttons) ->
                buttonElement = buttons.value[index-1].ELEMENT
                browser.elementIdClick buttonElement
                browser.pause 1000
                browser.waitForElementVisible '.kdnotification.main', 20000
                browser.assert.containsText '.kdnotification.main', 'This credential is currently in-use'
