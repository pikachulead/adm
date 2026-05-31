There is beauty in simplicity.
Good architecture is modular, with descriptive names and strong internal cohesion.
Resuse code, and avoid reinventing the wheel.
Test driven development with tests created first. 
Create end to end tests and validate before considering a component as complete.
Leverage widely adopted, community supported open source libraries like react, playwright, nodejs etc.
Use Typescript with well defined types and avoid use of any.
Adhere to existing Prettier and ESLint configurations.
Use `async/await` for asynchronous operations.
Use absolute imports (e.g., `@/components/`).
Avoid inline styles; use the established styling solution.
Ensure all code is i18n-friendly (avoid hard-coded strings).
Write clear, concise code that follows the DRY (Don't Repeat Yourself) principle.
Incremental Approach- Refactors must be incremental. Break down large tasks into small, verifiable steps.

Do not include any styling inside the components. IT should primarily be centralized. 
Make sure the code compiles and there are no errors.


1. Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:

State your assumptions explicitly. If uncertain, ask.
If multiple interpretations exist, present them - don't pick silently.
If a simpler approach exists, say so. Push back when warranted.
If something is unclear, stop. Name what's confusing. Ask.


2. Simplicity First
Minimum code that solves the problem. Nothing speculative.

No features beyond what was asked.
No abstractions for single-use code.
No "flexibility" or "configurability" that wasn't requested.
No error handling for impossible scenarios.
If you write 200 lines and it could be 50, rewrite it.
Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.


3. Surgical Changes
Touch only what you must. Clean up only your own mess.

When editing existing code:

Don't "improve" adjacent code, comments, or formatting.
Don't refactor things that aren't broken.
Match existing style, even if you'd do it differently.
If you notice unrelated dead code, mention it - don't delete it.
When your changes create orphans:

Remove imports/variables/functions that YOUR changes made unused.
Don't remove pre-existing dead code unless asked.
The test: Every changed line should trace directly to the user's request.