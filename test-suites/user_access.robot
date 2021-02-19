*** Settings ***
Resource    ../resources/resources_common/common_keywords.resource
Resource    ../resources/resources_common/common_utils.resource

Suite Setup    Open Chrome Browser
Suite Teardown    Close All Browsers

Documentation    Tests the user login and logout for different roles
Force Tags    user_access

*** Test Cases ***
As an Employee, Login and then logout from the iWorks Application

    Open iWorks Application
    Login To iWorks Application    ${USERNAME_EMPLOYEE}    ${PASSWORD_EMPLOYEE}
    Logout From iWorks Application


As an Employer, Login and then logout from the iWorks Application

    Login To iWorks Application    ${USERNAME_EMPLOYER}    ${PASSWORD_EMPLOYER}
    Logout From iWorks Application


As a Mediator, Login and then logout from the iWorks Application

    Login To iWorks Application    ${USERNAME_MEDIATOR}    ${PASSWORD_MEDIATOR}
    Logout From iWorks Application

