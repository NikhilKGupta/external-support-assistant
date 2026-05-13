public class ChannelDetector {
    public class Request {
        @InvocableVariable(
            label='Session ID'
            description='Messaging Session ID to determine channel type'
            required=true
        )
        public String sessionId;
    }
    public class Result {
        @InvocableVariable(
            label='Channel Type'
            description='Detected channel: Voice or Chat'
        )
        public String channelType;
    }
    @InvocableMethod(
        label='Detect Channel'
        description='Determines whether the session is on Voice or Chat channel'
    )
    public static List<Result> detect(List<Request> requests) {
        List<Result> results = new List<Result>();
        Set<Id> sessionIds = new Set<Id>();
        for (Request req : requests) {
            if (String.isNotBlank(req.sessionId)) {
                sessionIds.add(req.sessionId);
            }
        }

        Map<Id, MessagingSession> sessions = new Map<Id, MessagingSession>();
        if (!sessionIds.isEmpty()) {
            for (MessagingSession ms : [
                SELECT Id, MessagingChannel.DeveloperName,
                       MessagingChannel.MessageType
                FROM MessagingSession
                WHERE Id IN :sessionIds
                WITH USER_MODE
            ]) {
                sessions.put(ms.Id, ms);
            }
        }

        for (Request req : requests) {
            Result r = new Result();
            MessagingSession ms = sessions.get(req.sessionId);
            if (ms != null && ms.MessagingChannel != null) {
                String messageType = ms.MessagingChannel.MessageType;
                if (messageType != null && messageType.containsIgnoreCase('Voice')) {
                    r.channelType = 'Voice';
                } else {
                    r.channelType = 'Chat';
                }
            } else {
                r.channelType = 'Chat';
            }
            results.add(r);
        }
        return results;
    }
}
