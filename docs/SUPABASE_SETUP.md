# File storage on Supabase

Chat photos, videos, files and profile pictures are stored in Supabase Storage
(project `kndqxapcrpmktblezzts`). Sign-in is still Firebase: Supabase is set up
to trust Firebase sign-in tokens, and its rules only let each person upload
into, or delete from, their own folder. Files sent before the move keep working
because their Firebase links are saved in the messages.

The app already knows the project URL and publishable key (see
`lib/resources/media_storage.dart`). Publishable keys are meant to ship inside
apps; the storage rules decide who can do what.

## One-time setup (about 5 minutes)

### 1. Create the bucket and its rules

From the repo root:

```bash
supabase login
supabase link --project-ref kndqxapcrpmktblezzts
supabase db push
```

`db push` runs `supabase/migrations/20261013000000_echat_media_storage.sql`,
which creates the public `media` bucket (50 MB per file, the free-plan limit)
and the rules.

No CLI? Paste that SQL file into the Supabase dashboard > SQL Editor and run it.

### 2. Let Supabase trust Firebase sign-in

Supabase dashboard > Authentication > Sign In / Providers > **Third-party Auth**
> Add provider > **Firebase**, project ID `echat-888ef`.

(`supabase/config.toml` has the same setting for local development. Don't run
`supabase config push` against the live project unless you've checked the rest
of that file: it would overwrite the project's other auth settings.)

### 3. Deploy the notification server

The app asks the notification server (`server/`, on Vercel) to mark each
account as allowed to upload (`POST /supabase/role`, which adds the
`role: authenticated` claim Supabase needs). Vercel deploys it when the branch
is merged; nothing else to configure.

## Checking it works

Send a photo in a chat. It should appear in the dashboard under Storage >
`media` > `Media/<your uid>/`. If the upload fails, the app shows "Couldn't
send the photo" and the debug log says why:

| Log says | Fix |
| --- | --- |
| `Bucket not found` | Step 1 wasn't run. |
| `new row violates row-level security policy` / 403 | Step 2 is missing, or the server from step 3 isn't deployed yet. |
| `Storage access refused: 401` | The notification server can't verify Firebase tokens: check its `FIREBASE_SERVICE_ACCOUNT` env var on Vercel. |
| `Payload too large` | The file is over 50 MB. |

## Using a different project

Build with your own values:

```bash
flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
```
