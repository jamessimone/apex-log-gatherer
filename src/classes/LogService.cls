@RestResource(urlMapping='/logs/*')
global class LogService {
    //You can't debug the results of the ToolingApi class from
    //the Salesforce Developer Console - it struggles to display logs
    //within logs, if that makes sense. This is an alternative service so
    //that you can debug the results of your method calls.
    @HttpGet
    global static Map<String, String> getLogs() {
        return new ToolingApi().getLogs();
    }
}