# JobTrigger — Community Plan

Written 2026-11-16. A **proposal list**, not a plan of record: nothing here
is promoted. Status of record stays in `tasks/README.md`.

The student plan (Phase 21, epic STU: verified students get Pro free for
one year) is already built. This document lists **157 other ways** to make
JobTrigger useful to, and grow with, the developer community — especially
in Sri Lanka, where the owner can reach universities and meetups directly.

## How to read the tables

- **Size:** S = up to 2 days, M = up to 2 weeks, L = more than 2 weeks.
- **Type:** *Product* (code in the app, website or backend), *Programme*
  (a policy or offer, often a small config change), *Content*, *Outreach*.
- Anything that changes code still follows `CLAUDE.md` (§7 scope, §9 plan
  and approval). Any free or discounted plan reuses the entitlement source
  pattern built for students (Phase 20/21), so it is mostly configuration,
  not new billing code.

## A. Fair access (beyond students)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-01 | **Graduate offer**: when the student year ends, a discounted first year of Pro instead of a hard drop to Free | Keeps students who just started their first job | S | Programme |
| COM-02 | **Educator plan**: lecturers and lab instructors get Pro free while teaching | Teachers bring whole classes | M | Programme |
| COM-03 | **Open-source maintainer plan**: Pro free for maintainers of active public projects (verified through their GitHub account) | Maintainers are visible, vocal and often under-resourced | M | Programme |
| COM-04 | **Non-profit and NGO plan** | Small teams with real infrastructure and no budget | S | Programme |
| COM-05 | **Regional pricing** set per store country, so Pro costs a fair amount in Sri Lanka and similar markets | A US price is a big share of a local junior salary | S | Programme |
| COM-06 | **Bootcamp and training-centre seats** at a group price | Institutes teaching DevOps need a hands-on tool | M | Programme |
| COM-07 | **Hackathon codes**: time-limited Pro codes for event participants | Builders try it when they are building | S | Programme |
| COM-08 | **"Sponsor a seat"**: companies or users pay for Pro for a student or job-seeker | Community-funded access, good publicity for sponsors | M | Product |
| COM-09 | **Generous Free plan stays generous**: publish a promise of what Free will always include | Trust; people recommend tools that won't bait-and-switch | S | Programme |
| COM-10 | **Campus lab licence**: one university, many students, managed by a lecturer | Easier than every student verifying separately | L | Product |

## B. Learning and education

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-11 | **Learning labs in demo mode**: guided exercises ("trigger a build", "find why it failed", "approve a deployment") on the built-in demo data | Students learn CI/CD without running a server | M | Product |
| COM-12 | **Free practice Jenkins** for learners, reset every night | A safe real server to point the app at | M | Outreach |
| COM-13 | **CI/CD glossary** inside the app, linked from tricky terms (artifact, quality gate, runner, agent) | Juniors understand what they are looking at | S | Product |
| COM-14 | **Course kit for lecturers**: slides, lab sheets and a marking guide built around JobTrigger and a sample repo | Makes it easy to adopt in a module | M | Content |
| COM-15 | **Pipeline starter templates** (Jenkinsfile, GitHub Actions, SonarQube setup) for common stacks, on the website | Gets people from zero to a first green build | M | Content |
| COM-16 | **"From commit to production" learning path** on the website, one short article per stage | Ties the product to how people learn DevOps | M | Content |
| COM-17 | **Completion badge** for finishing the learning labs, shareable on LinkedIn | Students want proof of skills for job hunting | M | Product |
| COM-18 | **DevSecOps primer** using SonarQube and the security tools, drawn from the owner's research | Security is the gap most courses skip | M | Content |
| COM-19 | **Sinhala and Tamil versions** of the beginner guides | Reaches learners who are more comfortable in their first language | M | Content |

## C. Events and meetups

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-20 | **List DevOps meetups on Synode** (the owner's tech-events platform) and link them from JobTrigger's website | Two of the owner's products help each other | S | Outreach |
| COM-21 | **Monthly "Build Break" meetup** in Colombo: short talks on CI/CD failures and fixes | A regular place for the community to meet | M | Outreach |
| COM-22 | **University workshops**: a 90-minute hands-on CI/CD session for IT faculties | Direct reach to future users | S | Outreach |
| COM-23 | **Hackathon sponsorship** with a "best DevOps setup" prize | Rewards good engineering practice, not only demos | S | Outreach |
| COM-24 | **Online office hours** each month: bring your broken pipeline | Real help, and a source of product ideas | S | Outreach |
| COM-25 | **Talks at existing groups** (AWS User Group Colombo, IEEE student branches, FOSS communities) | Borrow existing audiences instead of building from zero | S | Outreach |
| COM-26 | **Campus ambassadors** at each university, with Pro, swag and a reference letter | Local champions spread it faster than ads | M | Programme |

## D. Open source

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-27 | **Publish the Jenkins API client as an open-source Dart package** on pub.dev | Other Flutter developers get a maintained client; JobTrigger gets visibility | M | Product |
| COM-28 | **Open-source the Jenkins test fixture** (`tools/jenkins-fixture`) for anyone testing Jenkins integrations | Reusable, low effort | S | Product |
| COM-29 | **Public issue tracker** for bugs and feature requests, with "good first issue" labels on the open-source parts | Lets the community help | S | Outreach |
| COM-30 | **Contribution guide** (setup, code style, how reviews work) for the open-source parts | Makes first contributions possible | S | Content |
| COM-31 | **Tool integration guide**: how a tool gets added (`docs/future-tools.md` §6) written for outsiders, so the community can propose and spec new tools | Demand and specs come from real users of each tool | M | Content |
| COM-32 | **Give back upstream**: report and fix bugs found in Jenkins, Flutter packages and SonarQube's API docs | Builds reputation in the communities the app depends on | S | Outreach |

## E. Feedback and co-creation

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-33 | **Public roadmap with voting**, fed by the "Need another tool? Tell us" link | Users see their requests count | M | Product |
| COM-34 | **Beta programme** through TestFlight and Play internal testing, open to anyone who signs up | Early users become advocates | S | Programme |
| COM-35 | **In-app feedback** with an optional screenshot (secrets hidden) | Easier than email, so more feedback | M | Product |
| COM-36 | **User advisory group**: 8–10 active users meeting every quarter | Direct input on priorities and pricing | S | Programme |
| COM-37 | **Feature request credits**: the first person to request a shipped feature is named in the release notes | Small, real recognition | S | Programme |
| COM-38 | **Public changelog** with a short story behind each release | Shows the product is alive | S | Content |

## F. Support and help

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-39 | **Community forum** (GitHub Discussions or a Discord server) with tool-specific channels | Users help each other; questions become searchable answers | S | Outreach |
| COM-40 | **Troubleshooting library** built from real support questions | Every answered email helps the next person | M | Content |
| COM-41 | **Response-time promise** for support email, published on the support page | Trust for a small product | S | Programme |
| COM-42 | **Setup videos**, one per tool, under 3 minutes | Many people learn faster by watching | M | Content |

## G. Trust and transparency

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-43 | **Security page with a disclosure policy** and `security.txt` | Researchers know how to report a bug safely | S | Product |
| COM-44 | **Bug bounty "hall of fame"** (thanks and Pro, not cash at first) | Encourages responsible reports on a small budget | S | Programme |
| COM-45 | **"How we protect your tokens"** article: encryption at rest, masked secrets, nothing in logs | The main fear about any CI app is token safety | S | Content |
| COM-46 | **Open numbers page**: users, uptime, releases (no personal data), from self-hosted Umami | Openness builds trust and press interest | M | Product |
| COM-47 | **Privacy-first defaults**, stated plainly: no ads, no selling data, analytics anonymous | A clear difference from ad-supported competitors | S | Content |
| COM-48 | **Third-party licences** screen kept complete and readable | Respects the open-source work the app is built on | S | Product |

## H. Inclusion and accessibility

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-49 | **Low-data mode**: slower polling, no images, small payloads | Mobile data is costly for many users | S | Product |
| COM-50 | **Accessibility statement** and a way to report barriers | Shows disabled users they are expected | S | Content |
| COM-51 | **Women in DevOps sessions** with local groups | Wider, more diverse pipeline of engineers | S | Outreach |
| COM-52 | **Free Pro for people between jobs** for a set period, by request | Helps people keep their skills sharp while job hunting | S | Programme |

## I. Recognition and growth

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-53 | **Referral rewards**: a free month of Pro for both people | Word of mouth, rewarded fairly | M | Product |
| COM-54 | **Contributor credits** screen in the app for translators, testers and contributors | Recognition costs nothing and matters | S | Product |
| COM-55 | **"Build of the week"** posts featuring interesting community pipelines (with permission) | Content that celebrates users | S | Content |
| COM-56 | **Case studies** of teams and students using JobTrigger | Proof for new users and for investors | M | Content |
| COM-57 | **Shareable success cards** ("100 builds fixed from my phone") users can post | Organic reach on LinkedIn | M | Product |

## J. Partnerships

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-58 | **Apply to the GitHub Student Developer Pack** as a partner offer | The student plan already exists; this puts it in front of millions of students | M | Outreach |
| COM-59 | **Join the Continuous Delivery Foundation** community and list JobTrigger in its landscape | Credibility in the CI/CD world | S | Outreach |
| COM-60 | **Get listed in Jenkins and SonarQube community resources** (community forums, awesome lists) | Users of those tools find the app where they already look | S | Outreach |
| COM-61 | **University partnerships** (IIT, SLIIT, University of Moratuwa, University of Colombo School of Computing, NSBM) for labs and final-year projects | A steady stream of new users each year | M | Outreach |
| COM-62 | **Industry body links** (SLASSCOM, ICTA, the Computer Society of Sri Lanka) for events and skills programmes | Reach companies and national programmes | M | Outreach |
| COM-63 | **Hosting partner credits** (Render, Vercel, cloud providers) bundled into workshops | Students get a complete free stack to practise on | M | Outreach |

## K. Community-driven product

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-64 | **Community translations** through an open translation platform, once localisation lands | Each language opens a new community | M | Product |
| COM-65 | **Shared pipeline recipes**: users publish and rate "how I set up X" guides on the website | Knowledge sharing in the product's own space | L | Product |
| COM-66 | **Template gallery for notification rules and dashboards** users can import | Good setups spread quickly | M | Product |
| COM-67 | **Community-proposed tool epics**: a template people fill in to request a tool with its API details | Turns requests into ready specs | S | Content |
| COM-68 | **Annual community survey** on tools, pain points and pricing | Data for the roadmap and for funding pitches | S | Programme |

## L. Fair access (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-69 | **Early-career discount** for developers in their first two years of work | The gap between student and senior salary is real | S | Programme |
| COM-70 | **Pay-what-you-can** option in lower-income countries | Access without guessing each market's price | M | Programme |
| COM-71 | **Public-sector discount** for government digital teams | Small budgets, important systems | S | Programme |
| COM-72 | **School ICT teachers** (A/L and O/L) get Pro free | Automation can start before university | S | Programme |
| COM-73 | **Meetup organisers** get Pro free | Organisers recommend tools to everyone they host | S | Programme |
| COM-74 | **Speaker codes**: conference speakers get codes to give their audience | Turns talks into trials | S | Programme |
| COM-75 | **Startup programme**: six months of Pro for incubator and accelerator teams | Startups grow into paying teams | M | Programme |
| COM-76 | **Scholarship seats** for women in tech programmes | Wider access to DevOps careers | S | Programme |
| COM-77 | **Hackathon winners** get a year of Pro | Rewards builders who ship | S | Programme |
| COM-78 | **Mentor plan**: volunteer mentors get Pro free while mentoring | Thanks the people who teach others | S | Programme |

## M. Learning (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-79 | **Weekly pipeline puzzle**: a broken demo build to diagnose in the app | Fun, repeatable practice | M | Product |
| COM-80 | **DevOps interview guide** with common questions and how to answer | Directly helps job seekers | M | Content |
| COM-81 | **Final-year project CI/CD starter kit** (repo template, pipeline, quality gate) | Every FYP should have a pipeline | M | Content |
| COM-82 | **Research dataset** of anonymised failure categories, opt-in only, for academics | Supports CI/CD research, including the owner's own field | L | Product |
| COM-83 | **Supervisor view**: lecturers open read-only links to their students' pipelines | Easier supervision of projects | L | Product |
| COM-84 | **Mentorship matching** between junior and senior DevOps engineers | Knowledge flows to people who need it | M | Programme |
| COM-85 | **Build in public streams** showing how JobTrigger is made | Teaches real-world engineering and builds an audience | S | Content |
| COM-86 | **Certification study notes** (Kubernetes, AWS DevOps, Jenkins) | Clear goals for learners | M | Content |
| COM-87 | **"DevOps from Sri Lanka" podcast** with local engineers | Local role models | M | Content |
| COM-88 | **School workshops** on automation basics | Early interest in the field | S | Outreach |
| COM-89 | **Sinhala and Tamil subtitles** for all videos | Wider reach at low cost | S | Content |
| COM-90 | **Certification exam fee scholarships** funded by a share of Pro revenue | Removes a real money barrier | M | Programme |
| COM-91 | **Mentored internships** where students write tool epics and integrations | Real experience, real output | L | Programme |
| COM-92 | **Open curriculum** on GitHub under a Creative Commons licence | Any lecturer can reuse and improve it | M | Content |

## N. Events (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-93 | **Annual DevOps Day**: a free one-day mini-conference | A yearly anchor for the community | L | Outreach |
| COM-94 | **Online hackathon** to write tool integration specs | Community builds the roadmap | M | Outreach |
| COM-95 | **Lightning talks** slot at Synode-listed events | Easy first stage for new speakers | S | Outreach |
| COM-96 | **Campus coding competitions** with a DevOps track | Brings CI/CD into student contests | S | Outreach |
| COM-97 | **Hybrid events** streamed for students outside Colombo | Fair access across the country | M | Outreach |
| COM-98 | **Regional meetups** in Kandy, Galle and Jaffna with local universities | Community beyond the capital | M | Outreach |
| COM-99 | **Lunch-and-learn sessions** at software companies | Reach working engineers where they are | S | Outreach |
| COM-100 | **Speaker coaching** for first-time community speakers | More, and more diverse, voices on stage | S | Programme |

## O. Open source (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-101 | **Open-source SonarQube API client** for Dart | No such client exists; SonarQube on mobile is empty ground | M | Product |
| COM-102 | **Open-source log viewer widget** (ANSI colours, search) as a Flutter package | Useful to any app showing terminal output | M | Product |
| COM-103 | **Open-source the secret scrubber** used for crash reports | Every project needs log redaction | M | Product |
| COM-104 | **Open-source the demo-mode fake CI data** for teaching and testing | Reusable classroom material | S | Product |
| COM-105 | **Take part in Hacktoberfest** with labelled issues | A yearly wave of contributors | S | Outreach |
| COM-106 | **Contributor mentoring season** (Summer of Code style) with small stipends or Pro | Grows long-term contributors | M | Programme |
| COM-107 | **Public architecture decision records** | Shows how and why things are built | S | Content |
| COM-108 | **OpenAPI description** of the backend API | Lets others build clients and tools | M | Product |
| COM-109 | **Sponsor upstream projects** the app relies on (Riverpod, dio and others) | Gives back to the projects that make the app possible | S | Programme |
| COM-110 | **CI status design kit** (icons, colours, wording) published openly | Consistent, accessible status design for everyone | S | Content |

## P. Feedback (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-111 | **Monthly community call** with demos of new features | Regular contact with the people using it | S | Outreach |
| COM-112 | **User interview programme** with Pro as a thank-you | Deep, honest feedback | S | Programme |
| COM-113 | **Usability tests at universities** | Real users, real friction found early | S | Outreach |
| COM-114 | **Public bug triage session**, streamed | Openness, and teaches triage | S | Outreach |
| COM-115 | **"Report a confusing message" button** next to errors | Fixes the copy that confuses people most | S | Product |
| COM-116 | **Optional quarterly satisfaction survey** in the app | A simple signal over time | S | Product |
| COM-117 | **Labs settings** where users opt into early features | Fast feedback before features ship to everyone | M | Product |

## Q. Support (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-118 | **Forum bot** that answers common questions and links the status page | Fast answers at any hour | M | Product |
| COM-119 | **Community moderators** with clear guidelines | A healthy, safe space as it grows | S | Programme |
| COM-120 | **Stack Overflow tag** watched by the team | Meets people where they ask | S | Outreach |
| COM-121 | **Support in Sinhala and Tamil** as well as English | Comfort for local users | M | Programme |
| COM-122 | **Known issues page** | Saves duplicate reports | S | Content |
| COM-123 | **Onboarding calls for educators** setting up a class | Removes setup friction for whole classes | S | Programme |
| COM-124 | **Code of conduct** for all community spaces and events | Safety and inclusion from day one | S | Content |

## R. Trust (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-125 | **Independent security review** each year, with a public summary | Proof, not promises | L | Programme |
| COM-126 | **Open-source licence report** for every release | Respects licences and makes audits easy | S | Product |
| COM-127 | **Data processing agreement template** for companies | Removes a blocker for company use | M | Content |
| COM-128 | **AI use policy**: what is sent, where, and how to turn it off | Trust before AI features ship | S | Content |
| COM-129 | **Uptime history** on the public status page | Shows reliability over time | S | Product |
| COM-130 | **Public incident write-ups** after outages | Honesty builds loyalty | S | Content |
| COM-131 | **Clear deletion and retention timelines** on the privacy page | People know what happens to their data | S | Content |

## S. Inclusion (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-132 | **Tested on low-end Android phones**, with a published minimum spec | Many students use budget phones | M | Product |
| COM-133 | **Right-to-left ready layouts** for future languages | Opens Arabic and Urdu-speaking communities later | M | Product |
| COM-134 | **Plain-language review** of all app and website text | Easier for non-native English speakers | S | Content |
| COM-135 | **Captions on every video** | Deaf and hard-of-hearing users, and silent viewing | S | Content |
| COM-136 | **Downloadable guides** (PDF) for offline study | Limited or costly internet | S | Content |
| COM-137 | **Event accessibility checklist** (venue access, captions, quiet room) | Everyone can attend | S | Programme |

## T. Recognition (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-138 | **Annual community awards** (best contributor, best teacher, best talk) | Celebrates the people who give time | S | Programme |
| COM-139 | **Opt-in contributor leaderboard** | Friendly motivation | M | Product |
| COM-140 | **Swag for contributors and ambassadors** | Visible pride, free advertising | S | Programme |
| COM-141 | **Testimonials wall** on the website, with permission | Social proof from real users | S | Content |
| COM-142 | **LinkedIn recommendations** for active student ambassadors | Real career value for volunteers | S | Programme |
| COM-143 | **Ambassador badge on Synode profiles** | Links the owner's two communities | S | Product |

## U. Partnerships (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-144 | **DevOps training institutes** bundle JobTrigger into their courses | Students learn on the tool they will use | M | Outreach |
| COM-145 | **Co-hosted events with local software companies** | Companies reach students; students reach jobs | S | Outreach |
| COM-146 | **Cloud credit programmes** for student and startup projects | Free infrastructure to practise on | M | Outreach |
| COM-147 | **Work with Jenkins and CDF ambassadors** in the region | Shared events and credibility | S | Outreach |
| COM-148 | **Listing in vendor integration pages** (Bitrise, SonarSource, GitLab) once supported | Users of each tool discover the app | S | Outreach |
| COM-149 | **National digital skills programmes** as a practical tool partner | Reach at country scale | M | Outreach |
| COM-150 | **Coworking spaces and libraries** as free event venues | Lower event costs, regular homes | S | Outreach |

## V. Community-driven product (more)

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-151 | **Integration SDK** so the community can build and propose new tools | Scales tool coverage beyond one developer | L | Product |
| COM-152 | **Community-made themes** | Personal expression; easy contributions | M | Product |
| COM-153 | **Public CI status pages for open-source projects**, read-only, for their contributors | Free help for open source, and visibility for JobTrigger | L | Product |
| COM-154 | **Community Q&A link inside the app** from help screens | Answers in context | S | Product |
| COM-155 | **"Tool of the quarter" vote** that decides the next integration | Users steer the roadmap | S | Programme |

## W. Giving back

| ID | Idea | Why it helps the community | Size | Type |
|---|---|---|---|---|
| COM-156 | **Share of revenue to local coding education** (for example school computer labs) | Profit that returns to the community | S | Programme |
| COM-157 | **Volunteer days** setting up CI/CD for NGOs for free | Real help for organisations that can't afford it | S | Outreach |

## Suggested first ten

Cheap and fast, and each one supports the next:
COM-58 GitHub Student Developer Pack, COM-01 graduate offer, COM-05 regional
pricing, COM-20 Synode meetup listings, COM-22 university workshops, COM-11
learning labs in demo mode, COM-39 community forum, COM-43 security page,
COM-45 token safety article, COM-34 open beta.

Several of these (case studies, the open numbers page, the survey,
university partnerships) also give hard evidence for funding conversations.
