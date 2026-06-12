import SwiftUI

struct DocsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDoc: Int

    init(initialTab: Int = 0) {
        _selectedDoc = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Bracket")
                        .font(.custom("HelveticaNeue", size: 28))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Text("done")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Tab selector
                HStack(spacing: 0) {
                    docTab("terms", index: 0)
                    docTab("privacy", index: 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Rectangle()
                    .fill(Color(white: 0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    if selectedDoc == 0 {
                        termsContent
                    } else {
                        privacyContent
                    }
                }
            }
        }
    }

    // MARK: - Tab

    private func docTab(_ label: String, index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedDoc = index } } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: selectedDoc == index ? .semibold : .regular))
                    .foregroundColor(selectedDoc == index ? .white : Color(white: 0.4))
                Rectangle()
                    .fill(selectedDoc == index ? Color.white : Color.clear)
                    .frame(height: 1.5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Terms Content

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            docTitle("Terms and Conditions")
            docMeta("Last updated: May 2026")

            docSection("1. Acceptance of Terms")
            docBody("By downloading, installing, or using this application you agree to be bound by these Terms of Service. If you do not agree do not use the app. These terms apply to all users worldwide regardless of location.")

            docSection("2. What This App Is")
            docBody("This app is an AI-powered decision support tool. It uses artificial intelligence to simulate possible outcomes of situations you describe and provides perspective to help you think through decisions.")
            docBody("This app is not and does not claim to be:")
            docBullet("A licensed therapist, psychologist, or mental health professional")
            docBullet("A medical professional or medical advice service")
            docBullet("A legal advisor or legal service")
            docBullet("A financial advisor or financial planning service")
            docBullet("A crisis intervention or emergency service")
            docBullet("A substitute for professional help of any kind")
            docBody("AI-generated responses in this app are simulations and observations. They are not professional advice. Never treat them as professional advice. Always consult a qualified professional for medical, legal, financial, mental health, or any other professional guidance.")

            docSection("3. Not a Crisis Service")
            docBody("This app is not equipped to handle mental health emergencies. If you are experiencing thoughts of self-harm, suicide, or any kind of crisis — stop using this app immediately and contact emergency services or a crisis helpline in your country.")
            docBody("Global crisis resources:")
            docBullet("International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres")
            docBullet("Crisis Text Line (US, UK, Canada, Ireland): Text HOME to 741741")
            docBullet("Samaritans (UK and Ireland): 116 123")
            docBullet("Lifeline (Australia): 13 11 14")
            docBullet("iCall (India): 9152987821")
            docBullet("Vandrevala Foundation (India): 1860-2662-345")
            docBody("The app may decline to respond to certain inputs that suggest crisis situations. This is a design decision not a substitute for real professional help.")

            docSection("4. AI-Generated Content")
            docBody("All responses are produced by artificial intelligence using Anthropic's Claude API.")
            docBody("You acknowledge and agree that:")
            docBullet("AI responses may be inaccurate, incomplete, or inappropriate for your specific situation")
            docBullet("Confidence percentages and simulation counts displayed in the app are illustrative framings of probabilistic AI reasoning and are not scientifically validated statistics")
            docBullet("The app does not literally run thousands of discrete simulations — this framing communicates uncertainty and probability in an accessible way")
            docBullet("No AI system can predict the future and no response should be treated as a guarantee of any outcome")
            docBullet("You use all responses entirely at your own risk and discretion")

            docSection("5. Your Responsibilities")
            docBody("You agree to:")
            docBullet("Use this app only for lawful personal purposes")
            docBullet("Not attempt to manipulate, jailbreak, or extract harmful information from the AI system")
            docBullet("Not use the app to plan or facilitate illegal activities")
            docBullet("Not rely solely on this app for major life decisions")
            docBullet("Take full responsibility for any decisions you make as a result of using this app")
            docBody("You are responsible for your own decisions. The app provides perspective. You provide judgment.")

            docSection("6. Eligibility")
            docBody("You must be at least 17 years old to use this app. By using the app you confirm you meet the minimum age requirement in your country or that you have parental consent where required.")
            docBody("If you are under 18 certain types of content and decisions may not be appropriate. Use good judgment.")

            docSection("7. Data and Privacy")
            docBody("Your thinks, chat history, and personal data are stored locally on your device. We do not collect, store, or have access to your personal think history on our servers.")
            docBody("Your inputs are sent to Anthropic's API for AI processing. Your inputs are therefore subject to Anthropic's privacy policy available at anthropic.com/privacy in addition to ours.")
            docBody("We recommend you do not enter sensitive personal information such as full legal names, addresses, financial account details, passport numbers, or government identification numbers into the app.")
            docBody("We do not sell your data. We do not share your data with third parties except as strictly required to operate the service.")
            docBody("For users in the European Economic Area and United Kingdom: You have rights under GDPR including the right to access, correct, and delete your personal data. Since all data is stored locally on your device you can delete it at any time by deleting the app. For any data processed through our API contact us at the address below.")
            docBody("For users in California: You have rights under the CCPA including the right to know what personal data is collected and the right to deletion. Contact us at the address below to exercise these rights.")
            docBody("For users in Australia: We comply with the Australian Privacy Act 1988 and the Australian Privacy Principles.")
            docBody("For full details see our Privacy Policy.")

            docSection("8. Subscription and Payments")
            docBody("The app offers a free tier with limited monthly usage and a paid subscription for unlimited access.")
            docBody("All subscriptions are processed through Apple's App Store. All billing, refunds, and subscription management are handled by Apple under their terms and conditions. We do not directly process or store payment information.")
            docBody("Subscription pricing may vary by country and is displayed in your local currency in the App Store before purchase.")
            docBody("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current billing period. Manage and cancel subscriptions through your Apple ID settings.")
            docBody("Refunds are handled by Apple. We do not offer direct refunds except where required by applicable law in your jurisdiction. EU and UK consumers have statutory rights including a 14-day cooling off period for digital purchases — contact Apple to exercise these rights.")

            docSection("9. Intellectual Property")
            docBody("All content, design, branding, and code in this app are owned by us or our licensors and are protected by international intellectual property laws.")
            docBody("You may not copy, reproduce, modify, distribute, or create derivative works from any part of this app without our explicit written permission.")
            docBody("Your inputs remain yours. By using the app you grant us a limited licence to process your inputs through our AI system solely for the purpose of generating responses to you. We do not claim ownership of your inputs and do not use them for training AI models.")

            docSection("10. Disclaimer of Warranties")
            docBody("This app is provided on an as-is and as-available basis worldwide. We make no warranties express or implied including but not limited to:")
            docBullet("Accuracy or reliability of AI responses")
            docBullet("Uninterrupted or error-free service")
            docBullet("Fitness for any particular purpose")
            docBullet("That the app will meet your specific requirements")
            docBody("Some jurisdictions do not allow the exclusion of implied warranties. In those jurisdictions our liability is limited to the minimum extent permitted by law.")

            docSection("11. Limitation of Liability")
            docBody("To the maximum extent permitted by applicable law in your jurisdiction we are not liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of this app.")
            docBody("This includes but is not limited to:")
            docBullet("Decisions made based on AI responses")
            docBullet("Loss of data if the app is deleted or malfunctions")
            docBullet("Any outcomes resulting from following or not following app suggestions")
            docBullet("Emotional distress arising from app content")
            docBody("Our total liability for any claim shall not exceed the greater of the amount you paid for the app in the twelve months preceding the claim or USD $10.")
            docBody("For EU and UK consumers: Nothing in these terms affects your statutory rights as a consumer which cannot be excluded or limited by contract.")
            docBody("For Australian consumers: Our goods and services come with guarantees that cannot be excluded under the Australian Consumer Law.")

            docSection("12. Indemnification")
            docBody("You agree to indemnify and hold harmless the app and its developers from any claims, damages, losses, or expenses including reasonable legal fees arising from your use of the app, your violation of these terms, or your violation of any third party rights.")

            docSection("13. App Store Terms")
            docBody("This app is distributed through Apple's App Store. Apple is not a party to these Terms of Service and is not responsible for the app or its content. Apple has no obligation to provide maintenance or support for this app. In the event of any claim that the app fails to conform to applicable legal warranty you may notify Apple and Apple will refund the purchase price if applicable.")

            docSection("14. Third Party Services")
            docBody("This app uses Anthropic's Claude API for AI processing. Use of the app constitutes acceptance of Anthropic's usage policies. We are not responsible for Anthropic's services, availability, or policies.")

            docSection("15. Prohibited Uses")
            docBody("You may not use this app to:")
            docBullet("Engage in any unlawful activity in any jurisdiction")
            docBullet("Harass, threaten, or harm any person")
            docBullet("Generate content that violates any applicable law")
            docBullet("Attempt to reverse engineer or extract the AI system prompt or model")
            docBullet("Resell or commercially exploit the app's AI responses")
            docBullet("Impersonate any person or entity")
            docBullet("Violate any applicable export control laws")

            docSection("16. Service Availability")
            docBody("We do not guarantee the app will be available at all times in all countries. We may restrict access in certain regions to comply with local laws. We reserve the right to modify, suspend, or discontinue the service at any time without notice.")

            docSection("17. Changes to Terms")
            docBody("We may update these terms at any time. We will notify you of material changes through the app or by updating the date at the top of this document. Continued use after changes constitutes acceptance of the updated terms. If you do not agree to the changes stop using the app.")

            docSection("18. Governing Law and Disputes")
            docBody("These terms are governed by the laws of India without regard to conflict of law principles.")
            docBody("For users outside India: You may also have rights under the laws of your own country that cannot be waived by this clause. Nothing in this section limits rights you have under the laws of your own jurisdiction.")
            docBody("For EU users: You may access the European Commission's Online Dispute Resolution platform at ec.europa.eu/consumers/odr")
            docBody("For UK users: You may contact the UK's Alternative Dispute Resolution service.")
            docBody("We encourage you to contact us directly to resolve any dispute before pursuing formal legal action.")

            docSection("19. Force Majeure")
            docBody("We are not liable for any failure to perform our obligations where such failure results from causes beyond our reasonable control including but not limited to Anthropic API downtime, Apple App Store outages, internet infrastructure failures, natural disasters, or government actions.")

            docSection("20. EU and UK Consumer Rights")
            docBody("For EU and UK consumers the indemnification clause in section 12 applies only to the extent permitted by applicable consumer protection law in your jurisdiction. Nothing in these terms removes or limits rights you have under EU or UK consumer protection law that cannot be waived by contract.")

            docSection("21. Severability")
            docBody("If any provision of these terms is found to be unenforceable in any jurisdiction that provision will be modified to the minimum extent necessary or severed. The remaining provisions continue in full force.")

            docSection("22. Entire Agreement")
            docBody("These Terms of Service and our Privacy Policy constitute the entire agreement between you and us regarding the app and supersede all prior agreements.")

            docSection("23. Contact")
            docBody("For questions, concerns, or legal notices:")
            docBody("Email: bracketapp26@gmail.com")
            docBody("Company: Andrew Wilson")
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 60)
    }

    // MARK: - Privacy Content

    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            docTitle("Privacy Policy")
            docMeta("Last updated: May 2026")

            docSection("Overview")
            docBody("This Privacy Policy describes how Bracket: Think It Through (\"we,\" \"our,\" or \"the app\") collects, uses, and protects your information when you use our iOS application. We built this app with privacy as our core priority. Your personal inputs stay on your device. We do not sell your data. We do not build advertising profiles. We do not share your personal information with third parties except as strictly necessary to provide the service as described below.")
            docBody("The brain provides perspective and simulation — not instructions. All decisions remain entirely yours.")

            docDivider

            docSection("What We Collect and How It Flows")

            docSubSection("1. Information You Provide — Thinks")
            docBody("When you use the app you submit situations, decisions, and feelings for processing. We refer to these text inputs as Thinks. The text you type into the app is transmitted directly to Anthropic's API for processing to generate responses. This is a technical necessity — without transmitting this input to the AI model the app cannot function.")

            docSubSection("2. Information Stored on Your Device")
            docBody("Your historic data — including the questions you submit, the verdicts and reasoning returned by the AI, your archetypes, your pattern identity, and any chat messages — is stored locally on your iPhone. We do not have remote access to your history. We cannot read it. We cannot retrieve it. It exists strictly on your device.")

            docSubSection("3. Technical Network Data — IP Address")
            docBody("When the app connects to the internet to process a request your device's IP address is transmitted to Anthropic's servers as part of standard network communication. We do not log, store, or track your IP address. Anthropic handles this data in accordance with their own privacy policy available at anthropic.com/privacy.")

            docSubSection("4. Notifications")
            docBody("If you explicitly grant permission the app sends occasional reminders. We do not collect or transmit any data through notifications. You can disable these at any time via your iPhone Settings or within the app Settings.")

            docSubSection("5. Usage Data and Analytics")
            docBody("We do not collect analytics, crash logs, or telemetry. We do not use third party analytics SDKs. We have zero visibility into how you interact with the app.")

            docSubSection("6. Purchase and Subscription Information")
            docBody("In-app purchases and subscriptions are processed securely by Apple via the App Store. We never see or store your payment or biometric data. We use RevenueCat to verify your subscription status. RevenueCat receives your anonymous App Store receipt to confirm active access. Their privacy policy is available at revenuecat.com/privacy.")

            docDivider

            docSection("How We Use Your Information")
            docBody("To provide the service — your text inputs are processed by Anthropic's Claude AI to generate verdicts, outcomes, and pattern analyses.")
            docBody("To improve personalization locally — the app passes a window of your locally stored history back to the AI during active sessions to deliver cohesive cross-session continuity. This history can be wiped instantly by you at any time from Settings.")
            docSection("We never:")
            docBullet("Use your data for advertising, marketing, or tracking")
            docBullet("Build data profiles to sell to third parties")
            docBullet("Use your data to train AI models — Anthropic's API policies explicitly state that data sent via their API is not used for model training by default")

            docDivider

            docSection("Legal Basis for Processing — GDPR")
            docBody("For users in the European Economic Area and United Kingdom — we process your personal data on the following legal bases:")
            docBoldBullet("Contractual necessity:", "Transmitting your Think text to Anthropic's API is required to deliver the core service you agreed to receive.")
            docBoldBullet("Consent:", "For notifications and local processing continuity.")
            docBody("You have the right to access, correct, and delete your personal data. Because all data is stored locally on your device, you exercise total control over this right—you can delete your data instantly at any time by clearing your history in Settings or deleting the app. Please note: Because we do not store your data on our own servers, we hold no records of your history and cannot delete or export it on your behalf. Text inputs sent to Anthropic's API are subject to Anthropic's data retention policies (which typically delete API inputs after 30 days and do not use them for training).")

            docDivider

            docSection("AI Disclosure and Consent")
            docBody("This app relies entirely on artificial intelligence to deliver its core experience. By using this application you acknowledge and agree that:")
            docBullet("Your text inputs are transferred to Anthropic's Claude AI for processing")
            docBullet("All insights, verdicts, and analyses are machine-generated not human-curated")
            docBullet("AI responses do not constitute professional advice — medical, legal, financial, or psychological therapy")
            docBullet("Confidence percentages and simulation counts are illustrative framings of probabilistic AI reasoning and are not scientifically validated statistics")
            docBullet("No AI system can predict the future and no response should be treated as a guarantee of any outcome")
            docBullet("You use all responses entirely at your own risk and discretion")
            docBullet("All decisions remain entirely yours")
            docBody("Crisis Warning: If you are experiencing a mental health crisis please contact a qualified healthcare professional or local emergency crisis service immediately. This app is not a crisis service.")

            docDivider

            docSection("International Data Transfers")
            docBody("This application is developed in India. When you submit inputs they are processed on Anthropic's servers located in the United States. By using this app you consent to the cross-border transfer of your data for the exclusive purpose of AI processing.")

            docDivider

            docSection("Your Rights, Controls, and Data Erasure")
            docBody("Because your data is held locally you have total sovereignty over it:")
            docSubItem("Clear Think History", "available in Settings. Permanently deletes all your thinks, pattern data, and brain memory from your device. Your subscription and usage counters are kept. Irreversible.")
            docSubItem("App Deletion", "uninstalling the app completely removes all local storage instantly.")
            docSubItem("Disable Notifications", "available in iPhone Settings or within the app Settings at any time.")
            docSubItem("Subscription Management", "cancel your Core or Pro subscription through iPhone Settings — Apple ID — Subscriptions. You retain access until the end of the current billing period.")
            docSubItem("Opt Out of AI Processing", "the core function of this app requires sending your inputs to Anthropic's AI. If you do not wish your inputs to be processed by AI you should not use this app.")
            docSubItem("Data Portability", "we do not possess your data on our servers and cannot provide a remote export file. You can manually copy or screenshot your data inside the app at any time.")

            docDivider

            docSection("Compliance with Indian Law — DPDP Act 2023")
            docBody("In compliance with the Digital Personal Data Protection Act 2023 India:")
            docSubItem("Consent and Withdrawal", "your processing is based entirely on your explicit consent given during onboarding. You have the right to withdraw consent at any time by discontinuing use and deleting the app or clearing your history.")
            docSubItem("Age Restriction", "this application is not intended for individuals under the age of 18. We do not knowingly process digital personal data from minors. If you are under 18 please do not use this app.")
            docSection("Grievance Redressal Mechanism")
            docBody("If you have questions, concerns, or complaints regarding how your data is handled or wish to exercise your legal rights under the DPDP Act, please contact our designated Grievance Officer:")
            docBoldBullet("Name:", "Andrew Wilson")
            docBoldBullet("Email:", "bracketapp26@gmail.com")
            docBoldBullet("App:", "Bracket: Think It Through")
            docBoldBullet("Website:", "https://bracketapp-navy.vercel.app")

            docDivider

            docSection("California Users — CCPA")
            docBody("We do not sell or share your personal information as defined under the California Consumer Privacy Act. We do not sell data to third parties. We do not share data for cross-context behavioral advertising.")

            docDivider

            docSection("Australian Users")
            docBody("We comply with the Australian Privacy Act 1988 and the Australian Privacy Principles.")

            docDivider

            docSection("Cookies and Tracking")
            docBody("This app does not use cookies, tracking pixels, or any cross-app tracking technology. We do not participate in any advertising networks or data broker services of any kind.")

            docDivider

            docSection("Data Breach Notification")
            docBody("In the unlikely event of a data breach affecting data transmitted through our API we will notify affected users within 72 hours of becoming aware of the breach in accordance with applicable law. Since all personal data is stored locally on your device and we operate no servers storing your personal information the risk of a data breach affecting your thinks is minimal.")

            docDivider

            docSection("Changes to This Policy")
            docBody("We may periodically update this document. The date at the top will reflect the latest revision. Continued use of the app after an update implies acknowledgment and acceptance of the revised terms. We review and update this privacy policy at least once every 12 months or whenever our data practices change.")

            docDivider

            docSection("Governing Law")
            docBody("This Privacy Policy is governed by the laws of India. Any legal disputes or claims arising out of this policy shall be subject to the exclusive jurisdiction of the courts located in Hyderabad Telangana India.")
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 60)
    }

    // MARK: - Shared Helpers

    private func docTitle(_ text: String) -> some View {
        Text(text)
            .font(.custom("HelveticaNeue-Bold", size: 22))
            .foregroundColor(.white)
            .padding(.bottom, 4)
    }

    private func docMeta(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Color(white: 0.35))
            .padding(.bottom, 28)
    }

    private func docSection(_ text: String) -> some View {
        Text(text)
            .font(.custom("HelveticaNeue-Bold", size: 15))
            .foregroundColor(.white)
            .padding(.top, 24)
            .padding(.bottom, 8)
    }

    private func docSubSection(_ text: String) -> some View {
        Text(text)
            .font(.custom("HelveticaNeue-Bold", size: 14))
            .foregroundColor(Color(white: 0.85))
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func docBody(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(white: 0.55))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 10)
    }

    private func docBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.4))
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.55))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 6)
        .padding(.leading, 8)
    }

    private func docBoldBullet(_ label: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.4))
            (Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(white: 0.75))
             + Text(" " + body).font(.system(size: 14, weight: .regular)).foregroundColor(Color(white: 0.55)))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 6)
        .padding(.leading, 8)
    }

    private func docSubItem(_ header: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(header)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(white: 0.75))
            Text(body)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(white: 0.55))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 12)
    }

    private var docDivider: some View {
        Rectangle()
            .fill(Color(white: 0.12))
            .frame(height: 1)
            .padding(.vertical, 20)
    }
}
