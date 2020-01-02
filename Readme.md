# Apex Log Gatherer

Gathering logs to export them from Salesforce, or even to view exceptions in one specific place, has historically been a painpoint of using SFDC. You can only view the Logs within setup, it's difficult to navigate there, and you can't perform any kind of programmatic logic based off an Apex object only available within the Tooling API.

This method is ready to be scheduled or used in other Apex to move your log data around / centralize the location of your exceptions.

## Pre-requisites

1. Deploy these classes to your Salesforce org
2. Insert a blank record in AuditLog\_\_c
3. You'll need to have active trace flags in order for this service to update them
4. You'll need to add your Salesforce base URL to the `This.remoteSite` file in `src/remoteSiteSettings/This.remoteSite`

## Notes

You can't debug the results of `ToolingApi.getLogs()` from within the Salesforce Developer Console. I've included `LogService` so that you can use an external service, like cURL or Postman, to display the log results, in the event that you wanted to do further processing; otherwise, you won't need the `LogService` class.

## Testing

Forthcoming.
