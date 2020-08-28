public interface ContactDAI {
    List<Contact> getContactsByEmail(List<String> emails);
    void insertContacts(List<Contact> contactsToInsert);
}