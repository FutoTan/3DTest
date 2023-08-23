using Godot;
using System;

public partial class Player : CharacterBody3D
{
	public const float Speed = 5.0f;
	public const float JumpVelocity = 4.5f;
	public const float MouseSensitivity = 0.1f;

	public float gravity = ProjectSettings.GetSetting("physics/3d/default_gravity").AsSingle();

	private Node3D _pivot;
	private Camera3D _camera;
	private RayCast3D _cameraCollider;

	public override void _Ready()
	{
		Input.MouseMode = Input.MouseModeEnum.Captured;

		_pivot = GetNode<Node3D>("Pivot");
		_camera = GetNode<Camera3D>("Pivot/Camera");
		_cameraCollider = GetNode<RayCast3D>("Pivot/CameraCollider");
	}

	public override void _Input(InputEvent @event)
	{
		if (@event is InputEventMouseMotion eventMouseMotion)
		{
			RotateY(Mathf.DegToRad(-eventMouseMotion.Relative.X * MouseSensitivity));
			_pivot.RotateX(Mathf.DegToRad(-eventMouseMotion.Relative.Y * MouseSensitivity));
			Vector3 rotation = _pivot.Rotation;
			rotation.X = Mathf.Clamp(rotation.X, Mathf.DegToRad(-90), Mathf.DegToRad(90));
			_pivot.Rotation = rotation;
		}
	}

	public override void _Process(double delta)
	{
		if (_cameraCollider.IsColliding()) {
			Transform3D globalTransform = _camera.GlobalTransform;
			globalTransform.Origin = _cameraCollider.GetCollisionPoint();
			_camera.GlobalTransform = globalTransform;
		} else {
			_camera.Position = _cameraCollider.TargetPosition;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		// Add the gravity.
		if (!IsOnFloor())
			velocity.Y -= gravity * (float)delta;

		// Handle Jump.
		if (Input.IsActionJustPressed("move_jump") && IsOnFloor())
			velocity.Y = JumpVelocity;

		// Get the input direction and handle the movement/deceleration.
		// As good practice, you should replace UI actions with custom gameplay actions.
		Vector2 inputDir = Input.GetVector("move_left", "move_right", "move_up", "move_down");
		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();
		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * Speed;
			velocity.Z = direction.Z * Speed;
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, Speed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, Speed);
		}

		Velocity = velocity;
		MoveAndSlide();
	}
}
