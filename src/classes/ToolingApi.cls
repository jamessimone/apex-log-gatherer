public class ToolingApi {
    private static final String TOOLING_API_URI = '/services/data/v47.0/tooling';
    private static final String LOG_BODY_QUERY = '/sobjects/ApexLog/{0}/Body/';
    private static final String TRACE_UPDATE_QUERY = '/sobjects/TraceFlag/{0}?_HttpMethod=PATCH';
    private static final String TRACE_DATE_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX';

    private final AuditLog__c auditLog;
    private final Http http;

    public ToolingApi() {
        this.auditLog = [SELECT Id, LastPoll__c, LastTraceFlagUpdate__c FROM AuditLog__c LIMIT 1];
        this.http = new Http();
    }

    public Map<String, String> getLogs() {
        Set<Id> logIds = this.queryLogIds();
        Map<String, String> logIdToLogBody = new Map<String, String>();
        for(Id logId : logIds) {
            HttpRequest logBodyReq = this.createHttpRequest();
            String logIdPath = String.format(LOG_BODY_QUERY, new List<String> { logId });
            logBodyReq.setEndpoint(logBodyReq.getEndpoint() + logIdPath);
            HttpResponse logBodyRes = this.http.Send(logBodyReq);
            logIdToLogBody.put(logId, logBodyRes.getBody());
        }

        String twelveHoursFromNow = System.now().addHours(12).format(TRACE_DATE_FORMAT);
        this.updateTraces(twelveHoursFromNow);
        this.updateAuditLog(twelveHoursFromNow);

        return logIdToLogBody;
    }

    private Set<Id> queryLogIds() {
        return new Map<Id, SObject>(
            [
                SELECT Id
                FROM ApexLog
                WHERE StartTime >= :this.auditLog.LastPoll__c
                AND Status != 'Success'
                AND Operation != 'Async Metadata'
                ORDER BY StartTime
                LIMIT 10
            ]
        ).keySet();
    }

    private HttpRequest getQueryRequest(String query) {
        HttpRequest request = this.createHttpRequest();
        query = query.replace(' ','+');
        request.setEndpoint(request.getEndpoint() + '/query?q=' + query);
        return request;
    }

    private HttpRequest createHttpRequest() {
        HttpRequest request = new HttpRequest();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('Make sure this URL is included in a Remote Site Setting: ' + baseUrl);
        request.setEndpoint(baseUrl + TOOLING_API_URI);
        request.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('GET');
        return request;
    }

    private void updateTraces(String twelveHoursFromNow) {
        String query = 'SELECT Id from TraceFlag where LogType = \'USER_DEBUG\'';
        HttpRequest request = this.getQueryRequest(query);
        HttpResponse res = this.http.Send(request);
        ToolingApiResponse toolingResponse = (ToolingApiResponse)Json.deserialize(res.getBody(), ToolingApiResponse.class);

        for(ToolingApiRecord traceRecord : toolingResponse.records) {
            HttpRequest traceRecordReq = this.createHttpRequest();
            traceRecordReq.setMethod('POST');
            String traceRecordBody = this.getTraceRecordBody(twelveHoursFromNow);
            System.debug(traceRecordBody);
            traceRecordReq.setBody(traceRecordBody);

            String traceRecordPath = String.format(TRACE_UPDATE_QUERY, new List<String> { traceRecord.Id });
            traceRecordReq.setEndpoint(traceRecordReq.getEndpoint() + traceRecordPath);
            this.http.Send(traceRecordReq);
        }
    }

    private void updateAuditLog(String twelveHoursFromNow) {
        this.auditLog.LastPoll__c = System.now();
        this.auditLog.LastTraceFlagUpdate__c = traceTimestamp;
        update this.auditLog;
    }

    private String getTraceRecordBody(String twelveHoursFromNow) {
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('StartDate', System.now().format(TRACE_DATE_FORMAT));
        gen.writeStringField('ExpirationDate', twelveHoursFromNow);
        gen.writeEndObject();
        return gen.getAsString();
    }

    private class ToolingApiResponse {
        List<ToolingApiRecord> records { get; set;}
    }

    private class ToolingApiRecord {
        Id Id { get; set; }
    }
}