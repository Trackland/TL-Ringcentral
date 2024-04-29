public with sharing class TL_RC_Main_Controller {
  @InvocableMethod(label='Init TL_RC_SMS_Controls' description='Initializes TL_RC_SMS_Controls with a timeout of 120 seconds')
  public static void initTLRCSMSControls() {
    TL_RC_SMS_Controls.init(120);
  }
}
