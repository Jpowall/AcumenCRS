public interface AccountDAI {
    List<Account> getAccountsByNames(List<String> accountNames);
    List<Account> getAccountsByIds(Set<Id> accountIds);
    void insertAccounts(List<Account> accountsToInsert);
}