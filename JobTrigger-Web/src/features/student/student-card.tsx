"use client";

import { useActionState, useState } from "react";

import { Field, Notice, SubmitButton } from "@/components/form";
import {
  STUDENT_ACCEPT,
  checkDocumentFile,
  documentProblemMessage,
  type DocumentProblem,
  type StudentApplication,
  type StudentStep,
} from "@/domain/student";

import {
  confirmStudentCodeAction,
  resendStudentCodeAction,
  startStudentEmailAction,
  uploadStudentDocumentAction,
  type StudentActionState,
} from "./actions";
import { studentDate } from "./student-text";

const card =
  "flex min-w-0 flex-[1_1_320px] flex-col gap-4 rounded-panel border border-line bg-card p-6.5 shadow-card";
const secondary =
  "h-11 self-start rounded-control border border-line-strong bg-card px-4 text-sm font-semibold text-fg hover:bg-raised disabled:opacity-70";
const linkButton = "self-start text-sm font-semibold text-accent underline underline-offset-2";

/**
 * The student plan on the Account page (SP-50). Shown only where billing is
 * on and the user is on Free or already a student. It renders the backend's
 * answer and runs the same flow as the app: a code to a university email, or
 * a student ID / enrolment letter when the domain isn't listed.
 */
export function StudentCard({ application }: { application: StudentApplication }) {
  const [tryAgain, setTryAgain] = useState(false);

  return (
    <section aria-labelledby="student-heading" className={card}>
      <h2 id="student-heading" className="text-[1.0625rem] font-bold">
        Student verification
      </h2>
      <Body application={application} tryAgain={tryAgain} onTryAgain={() => setTryAgain(true)} />
    </section>
  );
}

function Body({
  application,
  tryAgain,
  onTryAgain,
}: {
  application: StudentApplication;
  tryAgain: boolean;
  onTryAgain: () => void;
}) {
  const ends = studentDate(application.expiresAt);
  const expired = application.status === "expired";

  if (expired) {
    return (
      <p>
        Your student year has ended. The student plan is one free year per person, so your account
        is back on the Free plan.
      </p>
    );
  }
  if (application.status === "approved") {
    return (
      <p role="status">You have JobTrigger Pro as a student{ends ? `, free until ${ends}` : ""}.</p>
    );
  }
  // US-STU-01: a verified university email waits for review like a document.
  const byEmail = application.method === "email";
  if (application.status === "pending") {
    return (
      <>
        <p role="status" className="font-semibold">
          Pending review
        </p>
        <p className="text-sm text-muted">
          {byEmail
            ? "Your university email is verified. We review every application by hand, so it can take a few days. The result shows here and in the app."
            : "We've received your student document. We review them by hand, so it can take a few days. The result shows here and in the app."}
        </p>
      </>
    );
  }
  if (application.status === "rejected" && !tryAgain) {
    return (
      <>
        <Notice tone="error">
          {byEmail ? "We couldn't approve your application." : "We couldn't approve your document."}{" "}
          {application.rejectionReason ?? "Try again with a clearer photo or a different document."}
        </Notice>
        <button type="button" onClick={onTryAgain} className={secondary}>
          Try again
        </button>
      </>
    );
  }
  return <Verify />;
}

/** email → code, or document. The server actions say where to go next. */
function Verify() {
  const [step, setStep] = useState<StudentStep>({ step: "email" });
  const move = (state: StudentActionState) => {
    if (state.step) setStep(state.step);
    return state;
  };

  if (step.step === "code") {
    return <CodeStep email={step.email} onMove={move} onBack={() => setStep({ step: "email" })} />;
  }
  if (step.step === "document") {
    return (
      <DocumentStep
        domainNotListed={step.domainNotListed}
        onBack={() => setStep({ step: "email" })}
      />
    );
  }
  return (
    <EmailStep
      onMove={move}
      onDocument={() => setStep({ step: "document", domainNotListed: false })}
    />
  );
}

function EmailStep({
  onMove,
  onDocument,
}: {
  onMove: (state: StudentActionState) => StudentActionState;
  onDocument: () => void;
}) {
  const [state, action, pending] = useActionState(
    async (previous: StudentActionState, form: FormData) =>
      onMove(await startStudentEmailAction(previous, form)),
    {} as StudentActionState,
  );
  return (
    <>
      <p className="text-sm text-muted">
        Students get JobTrigger Pro free for one year. Verify with your university email.
      </p>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <form action={action} noValidate className="flex flex-col gap-4">
        <Field
          id="student-email"
          name="email"
          type="email"
          label="University email"
          autoComplete="email"
          placeholder="you@university.ac.lk"
        />
        <SubmitButton pending={pending}>Send code</SubmitButton>
      </form>
      <button type="button" onClick={onDocument} className={linkButton}>
        No university email? Upload a student ID
      </button>
    </>
  );
}

function CodeStep({
  email,
  onMove,
  onBack,
}: {
  email: string;
  onMove: (state: StudentActionState) => StudentActionState;
  onBack: () => void;
}) {
  const [state, action, pending] = useActionState(
    confirmStudentCodeAction,
    {} as StudentActionState,
  );
  const [resent, setResent] = useState<string | null>(null);
  const [resending, setResending] = useState(false);

  async function resend() {
    setResending(true);
    const next = onMove(await resendStudentCodeAction(email));
    setResent(next.error ?? "A new code is on its way.");
    setResending(false);
  }

  return (
    <>
      <p className="text-sm text-muted">
        We sent a 6-digit code to <strong className="text-fg">{email}</strong>. It works for 10
        minutes.
      </p>
      {resent && <Notice tone="info">{resent}</Notice>}
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <form action={action} noValidate className="flex flex-col gap-4">
        <Field
          id="student-code"
          name="code"
          label="Code"
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={6}
          placeholder="123456"
        />
        <SubmitButton pending={pending}>Verify</SubmitButton>
      </form>
      <button type="button" onClick={resend} disabled={resending} className={linkButton}>
        Send a new code
      </button>
      <button type="button" onClick={onBack} className={linkButton}>
        Use a different email
      </button>
    </>
  );
}

function DocumentStep({
  domainNotListed,
  onBack,
}: {
  domainNotListed: boolean;
  onBack: () => void;
}) {
  const [state, action, pending] = useActionState(
    uploadStudentDocumentAction,
    {} as StudentActionState,
  );
  const [problem, setProblem] = useState<DocumentProblem | null>(null);
  const [chosen, setChosen] = useState<string | null>(null);

  async function onFile(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) {
      setChosen(null);
      setProblem(null);
      return;
    }
    const found = await checkDocumentFile(file);
    setProblem(found);
    setChosen(found ? null : file.name);
    // A refused file must not travel: clear the input.
    if (found) event.target.value = "";
  }

  return (
    <>
      {domainNotListed && (
        <Notice tone="info">
          We can&apos;t check that email domain automatically. Upload a student ID or an enrolment
          letter instead.
        </Notice>
      )}
      <p className="text-sm text-muted">
        Upload a photo or PDF of your student ID or enrolment letter (JPG, PNG or PDF, up to 5 MB).
        We review it by hand and delete the file 30 days after we decide.
      </p>
      {problem && <Notice tone="error">{documentProblemMessage(problem)}</Notice>}
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <form action={action} noValidate className="flex flex-col gap-4">
        <Field
          id="student-name"
          name="fullName"
          label="Full name as on your student ID"
          autoComplete="name"
        />
        <Field
          id="student-file"
          name="file"
          type="file"
          label="Student ID or enrolment letter"
          accept={STUDENT_ACCEPT}
          onChange={onFile}
          hint={chosen ? <span className="text-sm text-muted">Selected: {chosen}</span> : undefined}
        />
        <SubmitButton pending={pending}>Send for review</SubmitButton>
      </form>
      <button type="button" onClick={onBack} className={linkButton}>
        Use a university email instead
      </button>
    </>
  );
}
