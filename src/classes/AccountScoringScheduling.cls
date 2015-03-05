global class AccountScoringScheduling implements Schedulable {
   global void execute(SchedulableContext sc) {
      AccountScoringBatch b = new AccountScoringBatch( 'Scheduled' ); 
      database.executebatch(b);
   }
}