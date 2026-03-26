sf data query --query "SELECT Id, Name, UrlPathPrefix FROM Network LIMIT 10" -o dhurandhar --json


sf data query --query "SELECT Id, DeveloperName FROM BotDefinition WHERE DeveloperName LIKE '%Workday_Support_Agent%' LIMIT 10" -o dhurandhar --json

sf data query --query "SELECT Id, BotDefinitionId, GenAiDocumentLibraryId FROM BotDefinitionGenAiDocumentLibrary WHERE BotDefinitionId = '0XxHu000001WZxdKAG' LIMIT 10" -o dhurandhar --json
SELECT Id, DeveloperName, Label FROM BotDefinition WHERE DeveloperName LIKE '%Workday_Support_Agent%'

