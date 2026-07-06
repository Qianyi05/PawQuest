# Firebase emulator tests

These tests always use the demo project ID `demo-pawquest`; they never connect
to the production PawQuest project.

Prerequisites: Node.js, Java 11+, and the Firebase CLI. Install dependencies
once with `npm install`, then run the complete suite with:

```sh
npm run test:firebase
```

The command starts isolated Authentication, Firestore, and Storage emulators,
runs every `*.test.cjs` file in this directory, and shuts the emulators down.
It covers the Auth-to-profile flow, profile validation and persistence, public
profile access, mirrored follow writes, forum comments/likes/notifications,
and avatar Storage rules.
