using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Translating : MonoBehaviour
{
    public float Speed = 10.0f;
    public Vector3 StartPoint = Vector3.zero;
    public Vector3 EndPoint = Vector3.zero;
    public Vector3 LookAt = Vector3.zero;
    public bool PingPong = true;

    private Vector3 _curEndPoint = Vector3.zero;
    
    
    // Start is called before the first frame update
    void Start()
    {
        transform.position = StartPoint;
        _curEndPoint = EndPoint;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = Vector3.Slerp(transform.position, _curEndPoint, Time.deltaTime * Speed);
        transform.LookAt(LookAt);
        if (PingPong) {
            if (Vector3.Distance(transform.position, _curEndPoint) < 0.001f) {
                _curEndPoint = Vector3.Distance(_curEndPoint, EndPoint) < Vector3.Distance(_curEndPoint, StartPoint) ? StartPoint : EndPoint;
            }
        }
    }
}
