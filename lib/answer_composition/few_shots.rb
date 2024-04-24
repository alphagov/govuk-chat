module AnswerComposition
  module FewShots
    FEW_SHOT1 = [
      {
        role: "user",
        content: "How can I find my utr number?",
      },
      {
        role: "assistant",
        content: <<~ANSWER1.freeze,
          <p>There are different ways to register if you’re:</p>
          <ul>
            <li>
              <a href=\"/register-for-self-assessment/self-employed\">self-employed (for example, a sole trader)</a>
            </li>
            <li>
              <a href=\"/register-for-self-assessment/not-self-employed\">not self-employed</a>
            </li>
            <li>
              <a href=\"/register-for-self-assessment/partner-or-partnership\">registering a partner or partnership</a>
            </li>
          </ul>

          <h2 id=\"when-to-register\">When to register</h2>

          <p>
            Once you’ve registered, you can <a href=\"/log-in-file-self-assessment-tax-return\">send your tax return online</a> any time before <a href=\"/self-assessment-tax-returns/deadlines\">the deadline</a>.
          </p>
        ANSWER1
      },
    ].freeze

    FEW_SHOT2 = [
      {
        role: "user",
        content: "How can I register for Self Assessment?",
      },
      {
        role: "assistant",
        content: <<~ANSWER2.freeze,
          <p>There are different ways to register if you’re:</p>
          <ul>
            <li>
              <a href=\"/register-for-self-assessment/self-employed\">self-employed (for example, a sole trader)</a>
            </li>
            <li>
              <a href=\"/register-for-self-assessment/not-self-employed\">not self-employed</a>
            </li>
            <li>
              <a href=\"/register-for-self-assessment/partner-or-partnership\">registering a partner or partnership</a>
            </li>
          </ul>

          <h2 id=\"when-to-register\">When to register</h2>

          <p>
            Once you’ve registered, you can <a href=\"/log-in-file-self-assessment-tax-return\">send your tax return online</a> any time before <a href=\"/self-assessment-tax-returns/deadlines\">the deadline</a>.
          </p>"""
        ANSWER2
      },
    ].freeze

    FEW_SHOT3 = [
      {
        role: "assistant",
        content: "How can I get a fishing licence?",
      },
      {
        role: "assistant",
        content: <<~ANSWER3.freeze,
          <p>The process for obtaining a fishing licence depends on the type of fishing you plan to do:</p>

          <h3>1. Fishing Vessel Licence (for vessels 10 metres or under)</h3>

          <p>
            If you want to catch and sell sea fish using a fishing vessel that is 10 metres or under, you will need a Category A fishing vessel licence. Here are the steps to obtain this licence:
          </p>
          <ol>
            <li>
              <a href="/fishing-vessel-licence-under-10-metres/register-your-vessel">Register your vessel</a> - You must do this before you can get a licence.
            </li>
            <li>
              <a href="/fishing-vessel-licence-under-10-metres/get-a-licence-entitlement">Get a licence entitlement</a> - You'll need this to get a licence.
            </li>
            <li>
              <a href="/fishing-vessel-licence-under-10-metres/apply-for-your-licence">Apply for your licence</a>.
            </li>
          </ol>
          <p>Make sure to carry your licence on board your vessel at all times.</p>

          <h3>2. Rod Fishing Licence (for salmon, trout, freshwater fish, smelt, and eels)</h3>

          <p>If you plan to fish for salmon, trout, freshwater fish, smelt, or eels with a rod and line in England and Wales, you will need a rod fishing licence. Here's how to obtain one:</p>
          <ul>
            <li>
              Check if you need a licence for the specific area you plan to fish. You need a licence for England (except the River Tweed), Wales, and the Border Esk region.
            </li>
            <li>
              Visit the <a href="https://get-fishing-licence.service.gov.uk/buy/new">Get Fishing Licence</a> website to buy a 1-day, 8-day, or 12-month licence online.
            </li>
            <li>
              Have the necessary information ready, such as your debit or credit card details, Blue Badge or National Insurance number (if applicable), and the details of the person you're buying the licence for (if applicable).
            </li>
            <li>
              Choose the type of licence and duration you want, and complete the online application process.
            </li>
          </ul>
          <p>
            There are different fees for different licence types and durations, so make sure to check the fees table on the website. Children under 13 do not need a licence, and licences for children aged 13 to 16 are free.</p> <p>If you prefer, you can also buy a licence by calling the Environment Agency at 0344 800 5386.
          </p>
          <p>
            Remember to always follow the rules and regulations for fishing in your area, and obtain any additional permissions or licences required, such as permission from landowners or specific licences for fishing in certain areas.
          </p>
        ANSWER3
      },
    ].freeze

    FEW_SHOTS = [FEW_SHOT1, FEW_SHOT2, FEW_SHOT3].freeze
  end
end
