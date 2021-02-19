*** Settings ***
Resource    ../resources/resources_common/common_keywords.resource
Resource    ../resources/resources_common/common_utils.resource

Suite Setup    Open Chrome Browser
Suite Teardown    Close All Browsers

Documentation    Tests the user login and logout for different roles
Force Tags    user_access_cucumber_format

*** Test Cases ***
As an Employee, Login and then logout from the iWorks Application

    Given Open iWorks Application
    When Login To iWorks Application    ${USERNAME_EMPLOYEE}    ${PASSWORD_EMPLOYEE}
    Then Logout From iWorks Application


As an Employer, Login and then logout from the iWorks Application

    When Login To iWorks Application    ${USERNAME_EMPLOYER}    ${PASSWORD_EMPLOYER}
    Then Logout From iWorks Application


As a Mediator, Login and then logout from the iWorks Application

    When Login To iWorks Application    ${USERNAME_MEDIATOR}    ${PASSWORD_MEDIATOR}
    Then Logout From iWorks Application

