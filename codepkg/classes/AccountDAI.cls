public interface AccountDAI {
    List<Account> getAccountsByNames(List<String> accountNames);
    void insertAccounts(List<Account> accountsToInsert);
}