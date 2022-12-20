*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             String
Library             RPA.PDF
Library             Collections
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocloud.Secrets
Library             OperatingSystem


*** Variables ***
#${Robot_Order_URL}=    https://robotsparebinindustries.com/#/robot-order
#${info_CSV_URL}=    https://robotsparebinindustries.com/orders.csv
${temp_folder_receipts}         ${OUTPUT_DIR}${/}temp_receipts
${temp_folder_screenshot}       ${OUTPUT_DIR}${/}temp_screenshot
${PATH}                         ${CURDIR}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${CSV_URL_orders}=    Collect order web URL from user
    Open the robot order website
    ${orders}=    Get orders    ${CSV_URL_orders}
    FOR    ${row}    IN    @{orders}
        Run Keyword And Ignore Error    Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Log    ${pdf}
        Log    ${screenshot}
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    URLs
    Open Available Browser    ${secret}[robot_order_URL]

Get orders
    [Arguments]    ${CSV_URL}
    Download    ${CSV_URL}    target_file=orders.csv    overwrite=True
    ${Orders_Table}=    Read table from CSV    orders.csv
    Log    Found columns: ${Orders_Table.columns}
    RETURN    ${Orders_Table}

Close the annoying modal
    Click Button    class:btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]

    ${default_body_xpath}=    Set Variable        xpath://input[@id="id-body-VALUE"][@type="radio"]
    ${final_radio_xpath}=    Replace String    ${default_body_xpath}    VALUE    ${row}[Body]
    Log    ${final_radio_xpath}
    Click Element    ${final_radio_xpath}

    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]

    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Element    id:preview

Submit the order
    Wait Until Keyword Succeeds    15x    0.5s    Click the order and wait for order completion

Click the order and wait for order completion
    Click Element    id:order
    Wait Until Page Contains Element    id:order-completion    1s

Go to order another robot
    Click Element    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${robot_receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${order_receipt_path}=    Set Variable    ${temp_folder_receipts}${/}order_receipt_${order_number}.pdf
    Html To Pdf    ${robot_receipt}    ${order_receipt_path}
    RETURN    ${order_receipt_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    ${robot_screenshot_path}=    Set Variable    ${temp_folder_screenshot}${/}order_screenshot_${order_number}.png
    ${robot_screenshot}=    Screenshot    id:robot-preview-image    ${robot_screenshot_path}
    RETURN    ${robot_screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close All Pdfs

    #Additional way to add image to a PDF file
    #${screenshot_list}=    Create List
    #Append To List    ${screenshot_list}    ${screenshot}
    #Add Files To Pdf    ${screenshot_list}    ${pdf}    append=True

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${temp_folder_receipts}    ${zip_file_name}

Collect order web URL from user
    Add text input    url    label=URL for robot order CSV file:
    ${response}=    Run dialog
    RETURN    ${response.url}
