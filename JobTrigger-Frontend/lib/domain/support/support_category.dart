/// P25-05: what kind of report this is. [wire] is the backend's enum value
/// (`JobTrigger-Backend/models/SupportTicket.js`); [label] is the chip text.
enum SupportCategory {
  bug('bug', 'Bug'),
  feature('feature', 'Feature idea'),
  question('question', 'Question'),
  toolRequest('tool_request', 'Tool request'),
  account('account', 'Account & sign-in'),
  billing('billing', 'Billing & subscription'),
  other('other', 'Something else');

  const SupportCategory(this.wire, this.label);

  final String wire;
  final String label;
}
