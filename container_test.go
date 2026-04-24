package s3website_test

import (
	"context"
	"io"
	"strings"
	"testing"
	"time"

	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"
)

// imageRepo and imageTag are used across tests so Docker can reuse the cached
// image layer instead of rebuilding from scratch for every test case.
const (
	imageRepo = "justinharringa/s3_website"
	imageTag  = "test"
)

// newContainer builds the Docker image from the local Dockerfile (using the
// Docker layer cache) and starts the container with the given cmd arguments.
// The container is expected to run a short-lived command and exit on its own.
func newContainer(ctx context.Context, t *testing.T, cmd []string) testcontainers.Container {
	t.Helper()

	req := testcontainers.ContainerRequest{
		FromDockerfile: testcontainers.FromDockerfile{
			Context:    ".",
			Dockerfile: "Dockerfile",
			Repo:       imageRepo,
			Tag:        imageTag,
			// KeepImage prevents Terminate from deleting the built image so that
			// subsequent test cases can reuse the Docker cache.
			KeepImage: true,
		},
		Cmd:        cmd,
		WaitingFor: wait.ForExit().WithExitTimeout(120 * time.Second),
	}

	c, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		t.Fatalf("failed to start container: %v", err)
	}

	return c
}

// containerOutput reads and returns the combined stdout+stderr logs from c.
func containerOutput(ctx context.Context, t *testing.T, c testcontainers.Container) string {
	t.Helper()

	rc, err := c.Logs(ctx)
	if err != nil {
		t.Fatalf("failed to retrieve container logs: %v", err)
	}
	defer rc.Close()

	output, err := io.ReadAll(rc)
	if err != nil {
		t.Fatalf("failed to read container logs: %v", err)
	}

	return string(output)
}

// TestDefaultHelp verifies that running the container with no additional
// arguments (using the default CMD ["help"]) prints s3_website usage text
// and exits with code 0.
func TestDefaultHelp(t *testing.T) {
	ctx := context.Background()

	c := newContainer(ctx, t, nil)
	defer func() {
		if err := c.Terminate(ctx); err != nil {
			t.Logf("warning: failed to terminate container: %v", err)
		}
	}()

	state, err := c.State(ctx)
	if err != nil {
		t.Fatalf("failed to get container state: %v", err)
	}
	if state.ExitCode != 0 {
		t.Errorf("expected exit code 0, got %d", state.ExitCode)
	}

	output := containerOutput(ctx, t, c)
	t.Logf("container output:\n%s", output)

	for _, want := range []string{"s3_website", "push", "help"} {
		if !strings.Contains(output, want) {
			t.Errorf("expected help output to contain %q\nactual output:\n%s", want, output)
		}
	}
}

// TestExplicitHelp verifies that passing "help" explicitly as a command
// argument produces the same usage text as the default CMD and exits 0.
func TestExplicitHelp(t *testing.T) {
	ctx := context.Background()

	c := newContainer(ctx, t, []string{"help"})
	defer func() {
		if err := c.Terminate(ctx); err != nil {
			t.Logf("warning: failed to terminate container: %v", err)
		}
	}()

	state, err := c.State(ctx)
	if err != nil {
		t.Fatalf("failed to get container state: %v", err)
	}
	if state.ExitCode != 0 {
		t.Errorf("expected exit code 0, got %d", state.ExitCode)
	}

	output := containerOutput(ctx, t, c)
	t.Logf("container output:\n%s", output)

	for _, want := range []string{"s3_website", "push", "help"} {
		if !strings.Contains(output, want) {
			t.Errorf("expected help output to contain %q\nactual output:\n%s", want, output)
		}
	}
}

// TestUnknownCommandExitCode verifies that passing an unrecognised subcommand
// causes the container to exit with a non-zero exit code.
func TestUnknownCommandExitCode(t *testing.T) {
	ctx := context.Background()

	c := newContainer(ctx, t, []string{"this-command-does-not-exist"})
	defer func() {
		if err := c.Terminate(ctx); err != nil {
			t.Logf("warning: failed to terminate container: %v", err)
		}
	}()

	state, err := c.State(ctx)
	if err != nil {
		t.Fatalf("failed to get container state: %v", err)
	}
	if state.ExitCode == 0 {
		output := containerOutput(ctx, t, c)
		t.Errorf("expected non-zero exit code for unknown command, got 0\noutput:\n%s", output)
	}
}
