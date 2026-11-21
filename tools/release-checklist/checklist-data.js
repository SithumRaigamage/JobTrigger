// Example data for release-checklist.html. Copy the HTML next to a file like
// this one and replace the contents for your project and release.
// Format: see README.md in this folder.
window.CHECKLIST = {
  project: "Example App",
  version: "1.0.0",
  targetDate: "not set",
  updated: "2026-11-22",
  intro: "Everything that has to happen before Example App 1.0.0 is public.",
  sections: [
    {
      id: "accounts",
      title: "Accounts to create",
      tasks: [
        {
          id: "play-account",
          title: "Create a Google Play developer account",
          who: "me",
          cost: "$25 one time",
          must: true,
          steps: [
            "Open the [Play Console sign-up page](https://play.google.com/console/signup).",
            "Choose a personal account and pay the fee.",
            "Confirm your identity when Google asks."
          ]
        }
      ]
    },
    {
      id: "launch",
      title: "Launch day",
      tasks: [
        {
          id: "publish",
          title: "Publish the app",
          who: "me",
          must: true,
          waitsFor: ["play-account"],
          steps: ["In Play Console, send the release to **Production**."]
        },
        {
          id: "announce",
          title: "Write the release notes",
          who: "claude",
          must: false,
          done: true,
          steps: ["Draft the notes from the merged changes."]
        }
      ]
    }
  ]
};
